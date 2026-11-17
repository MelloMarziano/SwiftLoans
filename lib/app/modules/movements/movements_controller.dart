import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/date_period.dart';
import '../../data/models/app_user.dart';
import '../../data/models/expense.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../clients/clients_controller.dart';
import '../expenses/widgets/expense_detail_sheet.dart';

enum MovementKind {
  /// Entrada: un cobro.
  payment('Cobros'),

  /// Salida: dinero prestado.
  disbursement('Préstamos'),

  /// Salida: gasto del negocio.
  expense('Gastos');

  const MovementKind(this.label);
  final String label;
}

/// Entrada o salida de dinero, con quién la hizo.
class Movement {
  const Movement({
    required this.kind,
    required this.date,
    required this.amount,
    required this.reference,
    required this.clientName,
    required this.byUid,
    required this.byName,
    this.method,
    this.payment,
    this.loan,
    this.expense,
  });

  factory Movement.fromPayment(Payment p, String clientName) => Movement(
    kind: MovementKind.payment,
    date: p.date,
    amount: p.amount,
    reference: p.id,
    clientName: clientName,
    byUid: p.collectorUid,
    byName: p.collector,
    method: p.method,
    payment: p,
  );

  factory Movement.fromLoan(Loan l, String clientName) => Movement(
    kind: MovementKind.disbursement,
    date: l.createdAt ?? l.startDate,
    amount: l.amount,
    reference: l.id,
    clientName: clientName,
    byUid: l.createdByUid,
    byName: l.createdBy ?? '',
    loan: l,
  );

  factory Movement.fromExpense(Expense e) => Movement(
    kind: MovementKind.expense,
    date: e.date,
    amount: e.amount,
    reference: e.id,
    clientName: e.title,
    byUid: e.byUid,
    byName: e.byName,
    method: e.method,
    expense: e,
  );

  final MovementKind kind;
  final DateTime date;

  /// Siempre positivo; el signo lo da [isIncome].
  final double amount;

  /// Recibo (R-…) o préstamo (P-…).
  final String reference;
  final String clientName;
  final String? byUid;
  final String byName;
  final PaymentMethod? method;
  final Payment? payment;
  final Loan? loan;
  final Expense? expense;

  bool get isIncome => kind == MovementKind.payment;
  double get signed => isIncome ? amount : -amount;
}

/// Movimientos de un día, para la lista agrupada.
class MovementDay {
  const MovementDay(this.day, this.items);

  final DateTime day;
  final List<Movement> items;

  double get net => items.fold(0, (s, m) => s + m.signed);
}

/// Totales del periodo.
class MovementTotals {
  MovementTotals(Iterable<Movement> items) {
    for (final m in items) {
      if (m.isIncome) {
        income += m.amount;
        final p = m.payment!;
        lateFee += p.lateFee;
        interest += p.interest;
        capital += p.capital;
        if (m.method == PaymentMethod.transfer) {
          transfer += m.amount;
        } else {
          cash += m.amount;
        }
        incomeCount++;
      } else {
        outcome += m.amount;
        if (m.kind == MovementKind.expense) {
          expenses += m.amount;
          expenseCount++;
        } else {
          loanCount++;
        }
      }
    }
  }

  double income = 0;
  double outcome = 0;
  double lateFee = 0;
  double interest = 0;
  double capital = 0;
  double cash = 0;
  double transfer = 0;
  int incomeCount = 0;
  int loanCount = 0;
  int expenseCount = 0;

  /// Parte de [outcome] que son gastos.
  double expenses = 0;

  double get net => income - outcome;
}

/// Entradas (cobros) y salidas (préstamos) por periodo. El cobrador solo ve
/// lo que él registró; dueño, administrador y ROOT ven todo.
class MovementsController extends GetxController {
  final _loans = Get.find<LoanRepository>();
  final _clients = Get.find<ClientRepository>();
  final _expenses = Get.find<ExpenseRepository>();
  final _auth = Get.find<AuthService>();
  final searchController = TextEditingController();

  final period = DatePeriod.today.obs;
  final customRange = Rxn<DateTimeRange>();
  final query = ''.obs;
  final kinds = <MovementKind>{}.obs;
  final methods = <PaymentMethod>{}.obs;

  /// UIDs de usuarios elegidos en el filtro "Cobrador" (solo gerentes).
  final people = <String>{}.obs;

  /// Todos los movimientos que este usuario puede ver (sin filtros).
  final all = <Movement>[].obs;

  /// Movimientos del periodo con los filtros aplicados, más nuevos primero.
  final visible = <Movement>[].obs;

  DateTime get today => _loans.today;

  AppUser? get _me => _auth.user.value;

  /// El cobrador solo ve lo suyo.
  bool get onlyMine => _me?.role == UserRole.collector;

  @override
  void onInit() {
    super.onInit();
    _build();
    everAll([
      _loans.payments,
      _loans.loans,
      _clients.clients,
      _expenses.expenses,
    ], (_) => _build());
    debounce(query, (_) => _apply(), time: const Duration(milliseconds: 250));
    everAll([period, customRange, kinds, methods, people], (_) => _apply());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  String _clientName(String id) => _clients.byId(id)?.name ?? 'Cliente $id';

  bool _isMine(Movement m) {
    final me = _me;
    if (me == null) return false;
    // Pagos anteriores al campo collectorUid: se compara el nombre.
    return m.byUid == null ? m.byName == me.name : m.byUid == me.uid;
  }

  void _build() {
    final list = [
      for (final p in _loans.allPayments)
        Movement.fromPayment(p, _clientName(p.clientId)),
      for (final l in _loans.loans)
        Movement.fromLoan(l, _clientName(l.clientId)),
      for (final e in _expenses.expenses) Movement.fromExpense(e),
    ];
    all.assignAll(onlyMine ? list.where(_isMine) : list);
    _apply();
  }

  (DateTime, DateTime) get range =>
      period.value.range(today, customRange.value);

  void _apply() {
    final (from, to) = range;
    final q = ClientsController.normalize(query.value.trim());
    final list = all.where((m) {
      if (m.date.isBefore(from) || !m.date.isBefore(to)) return false;
      if (kinds.isNotEmpty && !kinds.contains(m.kind)) return false;
      if (methods.isNotEmpty &&
          (m.method == null || !methods.contains(m.method))) {
        return false;
      }
      if (people.isNotEmpty && !people.contains(_personKey(m))) return false;
      if (q.isEmpty) return true;
      return ClientsController.normalize(m.clientName).contains(q) ||
          m.reference.toLowerCase().contains(q);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    visible.assignAll(list);
  }

  MovementTotals get totals => MovementTotals(visible);

  /// Lista agrupada por día (más reciente primero).
  List<MovementDay> get days {
    final groups = <DateTime, List<Movement>>{};
    for (final m in visible) {
      final d = DateTime(m.date.year, m.date.month, m.date.day);
      groups.putIfAbsent(d, () => []).add(m);
    }
    return [for (final e in groups.entries) MovementDay(e.key, e.value)];
  }

  // ---------- Filtros ----------

  static String _personKey(Movement m) =>
      m.byUid ?? (m.byName.isEmpty ? '?' : 'name:${m.byName}');

  /// Personas que aparecen en los movimientos: (clave, nombre).
  List<(String, String)> get availablePeople {
    final map = <String, String>{};
    for (final m in all) {
      map.putIfAbsent(
        _personKey(m),
        () => m.byName.isEmpty ? 'Sin registrar' : m.byName,
      );
    }
    return [for (final e in map.entries) (e.key, e.value)]
      ..sort((a, b) => a.$2.compareTo(b.$2));
  }

  bool get hasActiveFilters =>
      kinds.isNotEmpty || methods.isNotEmpty || people.isNotEmpty;

  void applyFilters({
    required Set<MovementKind> kinds,
    required Set<PaymentMethod> methods,
    required Set<String> people,
  }) {
    this.kinds.assignAll(kinds);
    this.methods.assignAll(methods);
    this.people.assignAll(people);
  }

  void resetFilters() =>
      applyFilters(kinds: const {}, methods: const {}, people: const {});

  void search(String value) => query.value = value;

  void clearSearch() {
    searchController.clear();
    query.value = '';
  }

  void changePeriod(DatePeriod value) => period.value = value;

  // ---------- Acciones ----------

  void open(Movement m) {
    if (m.payment != null) {
      Get.toNamed(Routes.paymentReceipt, arguments: m.payment!.id);
    } else if (m.loan != null) {
      Get.toNamed(Routes.loanDetail, arguments: m.loan!.id);
    } else if (m.expense != null) {
      ExpenseDetailSheet.show(m.expense!);
    }
  }
}
