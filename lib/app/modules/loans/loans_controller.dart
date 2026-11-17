import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/finance/loan_ledger.dart';
import '../../data/models/client.dart';
import '../../data/models/loan.dart';
import '../../data/models/loan_terms.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../clients/clients_controller.dart';

/// Situación de un préstamo a hoy.
enum LoanStatus {
  dueToday('Toca hoy'),
  upToDate('Al día'),
  overdue('Vencido'),
  paidOff('Saldado');

  const LoanStatus(this.label);
  final String label;

  static LoanStatus of(LoanSnapshot s) {
    if (s.balance == 0) return paidOff;
    if (s.overdueCount > 0) return overdue;
    if (s.dueToday > 0) return dueToday;
    return upToDate;
  }
}

/// Pestañas de la lista.
enum LoanTab {
  active('Activos'),
  today('Hoy'),
  overdue('Vencidos'),
  paidOff('Saldados'),
  all('Todos');

  const LoanTab(this.label);
  final String label;

  bool includes(LoanStatus s) => switch (this) {
    active => s != LoanStatus.paidOff,
    today => s == LoanStatus.dueToday,
    overdue => s == LoanStatus.overdue,
    paidOff => s == LoanStatus.paidOff,
    all => true,
  };
}

enum LoanSort {
  nextDue('Próximo vencimiento'),
  mostOverdue('Más atrasados'),
  balance('Mayor saldo'),
  newest('Más recientes');

  const LoanSort(this.label);
  final String label;
}

/// Préstamo con su cliente y su estado a hoy, listo para mostrar.
class LoanRow {
  LoanRow({required this.loan, required this.client, required DateTime today})
    : snapshot = LoanLedger.snapshot(loan, today) {
    status = LoanStatus.of(snapshot);
  }

  final Loan loan;
  final Client? client;
  final LoanSnapshot snapshot;
  late final LoanStatus status;

  String get clientName => client?.name ?? 'Cliente ${loan.clientId}';

  int get paidCount => loan.installments.where((i) => i.isPaid).length;

  /// Parte pagada de capital + interés (0 a 1).
  double get progress {
    final total = loan.totalDue;
    if (total <= 0) return 1;
    final pending = loan.installments.fold<double>(0, (s, i) => s + i.pending);
    return ((total - pending) / total).clamp(0, 1);
  }
}

/// Pantalla de Préstamos: resumen, filtros y lista. En pantallas anchas el
/// detalle se muestra al lado ([selectedId]).
class LoansController extends GetxController {
  final _loans = Get.find<LoanRepository>();
  final _clients = Get.find<ClientRepository>();
  final searchController = TextEditingController();

  final query = ''.obs;
  final tab = LoanTab.active.obs;
  final frequencies = <PaymentFrequency>{}.obs;
  final routes = <String>{}.obs;
  final sort = LoanSort.nextDue.obs;
  final selectedId = RxnString();

  /// Todos los préstamos con su estado (sin filtros).
  final rows = <LoanRow>[].obs;

  /// Lo que se ve tras aplicar pestaña, búsqueda, filtros y orden.
  final visible = <LoanRow>[].obs;

  DateTime get today => _loans.today;

  @override
  void onInit() {
    super.onInit();
    _build();
    everAll([_loans.loans, _clients.clients], (_) => _build());
    debounce(query, (_) => _apply(), time: const Duration(milliseconds: 250));
    everAll([tab, frequencies, routes, sort], (_) => _apply());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _build() {
    final now = today;
    rows.assignAll([
      for (final l in _loans.loans)
        LoanRow(loan: l, client: _clients.byId(l.clientId), today: now),
    ]);
    _apply();
  }

  void _apply() {
    final q = ClientsController.normalize(query.value.trim());
    final list = rows.where((r) {
      if (!tab.value.includes(r.status)) return false;
      if (frequencies.isNotEmpty && !frequencies.contains(r.loan.frequency)) {
        return false;
      }
      if (routes.isNotEmpty && !routes.contains(r.client?.route)) {
        return false;
      }
      if (q.isEmpty) return true;
      return ClientsController.normalize(r.clientName).contains(q) ||
          ClientsController.normalize(r.client?.alias ?? '').contains(q) ||
          r.loan.id.toLowerCase().contains(q) ||
          r.loan.clientId.contains(q);
    }).toList();

    // Saldados al final: no tienen próxima cuota.
    DateTime nextDue(LoanRow r) =>
        r.snapshot.nextInstallment?.dueDate ?? DateTime(9999);

    list.sort(
      (a, b) => switch (sort.value) {
        LoanSort.nextDue => nextDue(a).compareTo(nextDue(b)),
        LoanSort.mostOverdue =>
          b.snapshot.overdueCount.compareTo(a.snapshot.overdueCount) != 0
              ? b.snapshot.overdueCount.compareTo(a.snapshot.overdueCount)
              : nextDue(a).compareTo(nextDue(b)),
        LoanSort.balance => b.snapshot.balance.compareTo(a.snapshot.balance),
        LoanSort.newest => b.loan.startDate.compareTo(a.loan.startDate),
      },
    );
    visible.assignAll(list);
  }

  // ---------- Resumen ----------

  Iterable<LoanRow> get _open =>
      rows.where((r) => r.status != LoanStatus.paidOff);

  int get activeCount => _open.length;
  double get portfolio => _open.fold(0, (s, r) => s + r.snapshot.balance);

  Iterable<LoanRow> get _dueToday => rows.where((r) => r.snapshot.dueToday > 0);
  int get dueTodayCount => _dueToday.length;
  double get dueTodayAmount =>
      _dueToday.fold(0, (s, r) => s + r.snapshot.dueToday);

  Iterable<LoanRow> get _overdue =>
      rows.where((r) => r.status == LoanStatus.overdue);
  int get overdueCount => _overdue.length;

  /// Lo vencido sin contar la cuota de hoy (incluye mora).
  double get overdueAmount => _overdue.fold(
    0,
    (s, r) => s + r.snapshot.amountToBeCurrent - r.snapshot.dueToday,
  );
  double get lateFeeDue =>
      _overdue.fold(0, (s, r) => s + r.snapshot.lateFeeDue);

  Iterable<LoanRow> get _thisMonth {
    final now = today;
    return rows.where((r) {
      final d = r.loan.createdAt ?? r.loan.startDate;
      return d.year == now.year && d.month == now.month;
    });
  }

  int get disbursedCount => _thisMonth.length;
  double get disbursedAmount => _thisMonth.fold(0, (s, r) => s + r.loan.amount);

  int countFor(LoanTab t) => rows.where((r) => t.includes(r.status)).length;

  // ---------- Filtros ----------

  /// Rutas de los clientes que tienen préstamos.
  List<String> get availableRoutes =>
      {for (final r in rows) ?r.client?.route}.toList()..sort();

  bool get hasActiveFilters =>
      frequencies.isNotEmpty ||
      routes.isNotEmpty ||
      sort.value != LoanSort.nextDue;

  void applyFilters({
    required Set<PaymentFrequency> frequencies,
    required Set<String> routes,
    required LoanSort sort,
  }) {
    this.frequencies.assignAll(frequencies);
    this.routes.assignAll(routes);
    this.sort.value = sort;
  }

  void resetFilters() => applyFilters(
    frequencies: const {},
    routes: const {},
    sort: LoanSort.nextDue,
  );

  void search(String value) => query.value = value;

  void clearSearch() {
    searchController.clear();
    query.value = '';
  }

  void changeTab(LoanTab value) => tab.value = value;

  // ---------- Acciones ----------

  LoanRow? rowById(String id) => rows.firstWhereOrNull((r) => r.loan.id == id);

  /// En pantallas anchas selecciona; en móvil abre el detalle.
  void open(LoanRow row, {required bool sideBySide}) {
    if (sideBySide) {
      selectedId.value = row.loan.id;
    } else {
      Get.toNamed(Routes.loanDetail, arguments: row.loan.id);
    }
  }

  void collect(LoanRow row) => Get.toNamed(Routes.collect, arguments: row.loan);

  void newLoan() => Get.toNamed(Routes.loanRequest);
}
