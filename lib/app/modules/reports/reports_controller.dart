import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/finance/loan_ledger.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/date_period.dart';
import '../../data/models/app_user.dart';
import '../../data/models/expense.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';

/// Tramos de atraso de la cartera.
enum AgingBucket {
  current('Al día'),
  low('1–2 cuotas'),
  mid('3–5 cuotas'),
  high('6+ cuotas');

  const AgingBucket(this.label);
  final String label;

  static AgingBucket of(int overdue) => switch (overdue) {
    0 => current,
    <= 2 => low,
    <= 5 => mid,
    _ => high,
  };
}

class AgingRow {
  AgingRow(this.bucket);

  final AgingBucket bucket;
  int count = 0;
  double balance = 0;
}

/// Lo cobrado y gastado por cada usuario en el periodo.
class PersonRow {
  PersonRow(this.name);

  final String name;
  double collected = 0;
  int payments = 0;
  double expenses = 0;
}

/// Préstamo atrasado para la lista "Más atrasados".
class OverdueRow {
  const OverdueRow({
    required this.loan,
    required this.clientName,
    required this.overdueCount,
    required this.overdueAmount,
  });

  final Loan loan;
  final String clientName;
  final int overdueCount;
  final double overdueAmount;
}

/// Reportes del negocio por periodo: resultados, efectividad de cobro,
/// estado de la cartera y desempeño por usuario. El cobrador solo ve sus
/// propias cifras (cobros y gastos) y la cartera.
class ReportsController extends GetxController {
  final _loans = Get.find<LoanRepository>();
  final _clients = Get.find<ClientRepository>();
  final _expenses = Get.find<ExpenseRepository>();
  final _auth = Get.find<AuthService>();

  final period = DatePeriod.month.obs;
  final customRange = Rxn<DateTimeRange>();

  /// Cambia con cada dato nuevo para que la vista se recalcule.
  final _version = 0.obs;

  DateTime get today => _loans.today;

  AppUser? get _me => _auth.user.value;
  bool get onlyMine => _me?.role == UserRole.collector;

  @override
  void onInit() {
    super.onInit();
    everAll([
      _loans.payments,
      _loans.loans,
      _expenses.expenses,
      _clients.clients,
      period,
      customRange,
    ], (_) => _version.value++);
  }

  /// Registra la dependencia con los datos (usar dentro de Obx).
  void watch() => _version.value;

  (DateTime, DateTime) get range =>
      period.value.range(today, customRange.value);

  bool _inRange(DateTime d) {
    final (from, to) = range;
    return !d.isBefore(from) && d.isBefore(to);
  }

  bool _isMinePayment(Payment p) => p.collectorUid == null
      ? p.collector == _me?.name
      : p.collectorUid == _me?.uid;

  List<Payment> get periodPayments => _loans.allPayments
      .where((p) => _inRange(p.date))
      .where((p) => !onlyMine || _isMinePayment(p))
      .toList();

  List<Loan> get periodLoans => _loans.loans
      .where((l) => _inRange(l.createdAt ?? l.startDate))
      .where((l) => !onlyMine || l.createdByUid == _me?.uid)
      .toList();

  List<Expense> get periodExpenses => _expenses.expenses
      .where((e) => _inRange(e.date))
      .where((e) => !onlyMine || e.byUid == _me?.uid)
      .toList();

  // ---------- Resultados ----------

  double get collected => periodPayments.fold(0, (s, p) => s + p.amount);
  double get collectedInterest =>
      periodPayments.fold(0, (s, p) => s + p.interest);
  double get collectedLateFee =>
      periodPayments.fold(0, (s, p) => s + p.lateFee);
  double get collectedCapital =>
      periodPayments.fold(0, (s, p) => s + p.capital);
  double get disbursed => periodLoans.fold(0, (s, l) => s + l.amount);
  double get spent => periodExpenses.fold(0, (s, e) => s + e.amount);

  /// Ganancia: lo que entró por interés y mora menos los gastos (el capital
  /// cobrado solo recupera lo prestado).
  double get profit => collectedInterest + collectedLateFee - spent;

  /// Cuotas que vencieron en el periodo (hasta hoy) y cuánto de ellas ya
  /// está pagado. Mide qué tan bien se cobra.
  (double expected, double paid) get collectionEffectiveness {
    final (from, to) = range;
    final t = today;
    final end = DateTime(t.year, t.month, t.day + 1);
    final limit = to.isBefore(end) ? to : end;
    var expected = 0.0;
    var paid = 0.0;
    for (final l in _loans.loans) {
      for (final i in l.installments) {
        if (i.dueDate.isBefore(from) || !i.dueDate.isBefore(limit)) continue;
        expected += i.payment;
        paid += i.paidInterest + i.paidCapital;
      }
    }
    return (expected, paid);
  }

  /// Cobros y préstamos agrupados para el gráfico: por día si el periodo
  /// tiene hasta 14 días, si no por semana. Vacío para un solo día.
  List<DailyFlow> get flow {
    final (from, to) = range;
    final days = to.difference(from).inDays;
    if (days <= 1) return const [];

    final perDay = days <= 14;
    final step = perDay ? 1 : 7;
    final buckets = <(DateTime, DateTime)>[
      for (var d = from; d.isBefore(to); d = d.add(Duration(days: step)))
        (
          d,
          d.add(Duration(days: step)).isAfter(to)
              ? to
              : d.add(Duration(days: step)),
        ),
    ];
    const weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final payments = periodPayments;
    final loans = periodLoans;

    return [
      for (final (start, end) in buckets)
        DailyFlow(
          perDay
              ? (days <= 7
                    ? weekdays[start.weekday - 1]
                    : DateFormat('d').format(start))
              : DateFormat('d/M').format(start),
          payments
              .where((p) => !p.date.isBefore(start) && p.date.isBefore(end))
              .fold(0.0, (s, p) => s + p.amount),
          loans
              .where((l) {
                final d = l.createdAt ?? l.startDate;
                return !d.isBefore(start) && d.isBefore(end);
              })
              .fold(0.0, (s, l) => s + l.amount),
        ),
    ];
  }

  // ---------- Cartera (a hoy, no depende del periodo) ----------

  List<(Loan, LoanSnapshot)> get _openLoans => [
    for (final l in _loans.loans)
      if (!l.isPaidOff) (l, LoanLedger.snapshot(l, today)),
  ];

  List<AgingRow> get aging {
    final rows = {for (final b in AgingBucket.values) b: AgingRow(b)};
    for (final (_, s) in _openLoans) {
      final row = rows[AgingBucket.of(s.overdueCount)]!;
      row.count++;
      row.balance += s.balance;
    }
    return rows.values.toList();
  }

  double get portfolio => _openLoans.fold(0, (s, x) => s + x.$2.balance);

  /// Parte de la cartera con cuotas vencidas.
  double get atRiskRatio {
    final total = portfolio;
    if (total == 0) return 0;
    final risk = _openLoans
        .where((x) => x.$2.overdueCount > 0)
        .fold(0.0, (s, x) => s + x.$2.balance);
    return risk / total;
  }

  List<OverdueRow> get mostOverdue {
    final rows = [
      for (final (l, s) in _openLoans)
        if (s.overdueCount > 0)
          OverdueRow(
            loan: l,
            clientName:
                _clients.byId(l.clientId)?.name ?? 'Cliente ${l.clientId}',
            overdueCount: s.overdueCount,
            overdueAmount: s.amountToBeCurrent - s.dueToday,
          ),
    ]..sort((a, b) => b.overdueAmount.compareTo(a.overdueAmount));
    return rows.take(5).toList();
  }

  // ---------- Por usuario ----------

  List<PersonRow> get byPerson {
    final rows = <String, PersonRow>{};
    PersonRow rowFor(String? uid, String name) => rows.putIfAbsent(
      uid ?? 'name:$name',
      () => PersonRow(name.isEmpty ? 'Sin registrar' : name),
    );
    for (final p in periodPayments) {
      rowFor(p.collectorUid, p.collector)
        ..collected += p.amount
        ..payments += 1;
    }
    for (final e in periodExpenses) {
      rowFor(e.byUid, e.byName).expenses += e.amount;
    }
    return rows.values.toList()
      ..sort((a, b) => b.collected.compareTo(a.collected));
  }

  /// Gastos del periodo por categoría, de mayor a menor.
  List<(ExpenseCategory, double)> get expensesByCategory {
    final map = <ExpenseCategory, double>{};
    for (final e in periodExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return [for (final e in map.entries) (e.key, e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
  }

  void openLoan(Loan loan) =>
      Get.toNamed(Routes.loanDetail, arguments: loan.id);

  void openExpenses() => Get.toNamed(Routes.expenses);
}
