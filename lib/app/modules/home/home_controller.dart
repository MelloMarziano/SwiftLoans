import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/finance/loan_ledger.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../root/root_controller.dart';

class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class DailyFlow {
  const DailyFlow(this.day, this.collections, this.disbursements);

  final String day;
  final double collections;
  final double disbursements;
}

enum DashboardPeriod {
  today('Hoy'),
  week('Esta semana'),
  month('Este mes'),
  year('Este año');

  const DashboardPeriod(this.label);
  final String label;
}

/// Datos del dashboard. Por ahora son de ejemplo; se conectarán a Supabase.
class HomeController extends GetxController {
  static const quickActions = <QuickAction>[
    QuickAction(
      label: 'Cobrar',
      icon: LucideIcons.banknote,
      route: Routes.collect,
    ),
    QuickAction(
      label: 'Solicitud',
      icon: LucideIcons.filePlus,
      route: Routes.loanRequest,
    ),
    QuickAction(
      label: 'Gastos',
      icon: LucideIcons.wallet,
      route: Routes.expenses,
    ),
    QuickAction(
      label: 'Cuadre',
      icon: LucideIcons.clipboardCheck,
      route: Routes.cashClosing,
    ),
  ];

  final period = DashboardPeriod.month.obs;

  // Todo se calcula con los datos reales de la empresa (ver _recompute).
  final activePortfolio = 0.0.obs;

  /// Variación de la cartera en el mes (%); null si no hay base para compararla.
  final portfolioGrowth = RxnDouble();

  final clientsCount = 0.obs;
  final clientsDelta = 0.obs;
  final loansCount = 0.obs;
  final loansDelta = 0.obs;
  final overdueCount = 0.obs;
  final overdueDelta = 0.obs;

  final weeklyFlow = <DailyFlow>[].obs;

  final _clients = Get.find<ClientRepository>();
  final _loans = Get.find<LoanRepository>();

  @override
  void onInit() {
    super.onInit();
    _recompute();
    everAll([
      _clients.clients,
      _loans.loans,
      _loans.payments,
    ], (_) => _recompute());
  }

  void _recompute() {
    final now = _loans.today;
    final monthStart = DateTime(now.year, now.month);
    bool thisMonth(DateTime? d) => d != null && !d.isBefore(monthStart);

    final clients = _clients.clients;
    final active = _loans.loans.where((l) => !l.isPaidOff).toList();
    final overdue = active
        .where((l) => LoanLedger.snapshot(l, now).overdueCount > 0)
        .toList();

    clientsCount.value = clients.length;
    clientsDelta.value = clients.where((c) => thisMonth(c.createdAt)).length;
    loansCount.value = active.length;
    loansDelta.value = _loans.loans.where((l) => thisMonth(l.createdAt)).length;
    overdueCount.value = overdue.length;
    // Vencidos "nuevos": su primera cuota atrasada venció este mes.
    overdueDelta.value = overdue.where((l) {
      final first = l.installments.firstWhereOrNull(
        (i) => LoanLedger.isOverdue(i, now),
      );
      return first != null && !first.dueDate.isBefore(monthStart);
    }).length;

    // Cartera = lo que deben los clientes (capital + interés).
    final portfolio = clients.fold<double>(0, (s, c) => s + c.balance);
    activePortfolio.value = portfolio;

    // Variación del mes: lo prestado menos lo cobrado (capital + interés).
    final lent = _loans.loans
        .where((l) => thisMonth(l.createdAt))
        .fold<double>(0, (s, l) => s + l.totalDue);
    final collected = _loans.payments
        .where((p) => thisMonth(p.date))
        .fold<double>(0, (s, p) => s + p.interest + p.capital);
    final start = portfolio - (lent - collected);
    portfolioGrowth.value = start > 0 ? (lent - collected) / start * 100 : null;

    // Semana actual (lunes a domingo): cobros y desembolsos por día.
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    int? dayIndex(DateTime? d) {
      if (d == null) return null;
      final diff = DateTime(d.year, d.month, d.day).difference(monday).inDays;
      return diff >= 0 && diff < 7 ? diff : null;
    }

    final collections = List<double>.filled(7, 0);
    final disbursements = List<double>.filled(7, 0);
    for (final p in _loans.payments) {
      final i = dayIndex(p.date);
      if (i != null) collections[i] += p.amount;
    }
    for (final l in _loans.loans) {
      final i = dayIndex(l.createdAt);
      if (i != null) disbursements[i] += l.amount;
    }
    weeklyFlow.assignAll([
      for (var i = 0; i < 7; i++)
        DailyFlow(days[i], collections[i], disbursements[i]),
    ]);
  }

  /// Día seleccionado en el gráfico; null muestra el total de la semana.
  final selectedDay = RxnInt();

  int get activeLoans => loansCount.value - overdueCount.value;
  double get activeRatio =>
      loansCount.value == 0 ? 0 : activeLoans / loansCount.value;
  double get overdueRatio =>
      loansCount.value == 0 ? 0 : overdueCount.value / loansCount.value;

  double get collectionsShown => selectedDay.value == null
      ? weeklyFlow.fold(0, (sum, d) => sum + d.collections)
      : weeklyFlow[selectedDay.value!].collections;

  double get disbursementsShown => selectedDay.value == null
      ? weeklyFlow.fold(0, (sum, d) => sum + d.disbursements)
      : weeklyFlow[selectedDay.value!].disbursements;

  void changePeriod(DashboardPeriod value) => period.value = value;

  void toggleDay(int index) =>
      selectedDay.value = selectedDay.value == index ? null : index;

  void openQuickAction(QuickAction action) => Get.toNamed(action.route);

  void goToTab(int index) => Get.find<RootController>().changeTab(index);
}
