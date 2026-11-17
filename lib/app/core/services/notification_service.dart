import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/app_user.dart';
import '../../data/models/cash_closing.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/closing_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../finance/cash_summary.dart';
import '../finance/loan_ledger.dart';
import '../utils/formatters.dart';
import 'auth_service.dart';
import 'demo_mode.dart';
import 'key_value_store.dart';
import 'session_service.dart';

enum NotificationKind {
  dueToday('Cobros'),
  overdue('Cobros'),
  paidOff('Préstamos'),
  newLoan('Préstamos'),
  fund('Cuadre'),
  closingReviewed('Cuadre'),
  closingPending('Cuadre'),
  closingMissing('Cuadre');

  const NotificationKind(this.group);

  /// Filtro de la pantalla al que pertenece.
  final String group;
}

/// Aviso generado a partir de los datos de la empresa.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.date,
    this.route,
    this.arguments,
    this.urgent = false,
  });

  /// Cambia cuando el aviso cambia (p. ej. más cuotas vencidas), así vuelve
  /// a aparecer como no leído.
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime date;
  final String? route;
  final Object? arguments;

  /// Requiere atención (atrasos, faltantes).
  final bool urgent;
}

/// Calcula las notificaciones del usuario según su rol y recuerda en este
/// teléfono cuáles ya leyó. No necesita servidor: se recalculan cuando
/// cambian los datos y funcionan sin conexión.
class NotificationService extends GetxService {
  NotificationService({required KeyValueStore store}) : _store = store;

  final KeyValueStore _store;
  final _loans = Get.find<LoanRepository>();
  final _clients = Get.find<ClientRepository>();
  final _closings = Get.find<ClosingRepository>();
  final _expenses = Get.find<ExpenseRepository>();
  final _auth = Get.find<AuthService>();

  /// Más recientes primero.
  final notifications = <AppNotification>[].obs;
  final _read = <String>{}.obs;

  /// Días hacia atrás que se revisan.
  static const days = 14;

  DateTime get now => _loans.today;
  AppUser? get _me => _auth.user.value;
  bool get _manages {
    final role = _me?.role;
    return role == UserRole.root || (role?.managesUsers ?? false);
  }

  String get _readKey => 'notifications.read.${_me?.uid ?? '-'}';

  int get unreadCount => notifications.where((n) => !isRead(n)).length;

  bool isRead(AppNotification n) => _read.contains(n.id);

  @override
  void onInit() {
    super.onInit();
    _loadRead();
    ever(_auth.user, (_) => _loadRead());
    final changed = 0.obs;
    everAll([
      _loans.loans,
      _loans.payments,
      _clients.clients,
      _closings.closings,
      _closings.funds,
      _expenses.expenses,
      _auth.user,
    ], (_) => changed.value++);
    debounce(
      changed,
      (_) => recompute(),
      time: const Duration(milliseconds: 250),
    );
    everAll([notifications, _read], (_) => _publishBadge());
    recompute();
  }

  void _loadRead() {
    // En la demo cada sesión empieza con todo sin leer.
    if (DemoMode.active) {
      _read.clear();
      return;
    }
    final saved = _store.read<List<dynamic>>(_readKey);
    _read.assignAll(saved?.cast<String>() ?? const []);
  }

  void _saveRead() {
    if (DemoMode.active) return;
    // Solo se guardan los que siguen vigentes, para no crecer sin fin.
    final current = {for (final n in notifications) n.id};
    _store.write(_readKey, _read.where(current.contains).toList());
  }

  void _publishBadge() {
    if (Get.isRegistered<SessionService>()) {
      Get.find<SessionService>().unreadNotifications.value = unreadCount;
    }
  }

  void markRead(AppNotification n) {
    if (_read.add(n.id)) _saveRead();
  }

  void markAllRead() {
    _read.addAll(notifications.map((n) => n.id));
    _saveRead();
  }

  void recompute() {
    // Por día (más reciente primero); dentro del día, el resumen de cobros
    // arriba, luego lo urgente y luego por hora.
    DateTime day(AppNotification n) =>
        DateTime(n.date.year, n.date.month, n.date.day);
    int rank(AppNotification n) => n.kind == NotificationKind.dueToday
        ? 0
        : n.urgent
        ? 1
        : 2;
    notifications.assignAll(
      build()..sort((a, b) {
        final byDay = day(b).compareTo(day(a));
        if (byDay != 0) return byDay;
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : b.date.compareTo(a.date);
      }),
    );
    _publishBadge();
  }

  static final _day = DateFormat('yyyyMMdd');
  static final _short = DateFormat('dd/MM');

  /// Todas las notificaciones vigentes para el usuario en sesión.
  List<AppNotification> build() {
    final me = _me;
    if (me == null) return <AppNotification>[];
    final t = now;
    final today = DateTime(t.year, t.month, t.day);
    final since = today.subtract(const Duration(days: days));
    final list = <AppNotification>[];
    String clientName(String id) => _clients.byId(id)?.name ?? 'Cliente $id';

    // ---- Cobros de hoy y atrasos ----
    var dueCount = 0;
    var dueAmount = 0.0;
    for (final loan in _loans.loans) {
      if (loan.isPaidOff) continue;
      final s = LoanLedger.snapshot(loan, t);
      if (s.dueToday > 0) {
        dueCount++;
        dueAmount += s.dueToday;
      }
      if (s.overdueCount > 0) {
        final oldest = loan.installments.firstWhere(
          (i) => LoanLedger.isOverdue(i, t),
        );
        final since = oldest.dueDate.add(const Duration(days: 1));
        list.add(
          AppNotification(
            id: 'overdue-${loan.id}-${s.overdueCount}',
            kind: NotificationKind.overdue,
            title: '${clientName(loan.clientId)} está atrasado',
            body:
                '${s.overdueCount} ${s.overdueCount == 1 ? 'cuota vencida' : 'cuotas vencidas'}'
                ' · mora ${Formatters.currency2(s.lateFeeDue)} · '
                'para ponerse al día ${Formatters.currency2(s.amountToBeCurrent)}',
            date: DateTime(since.year, since.month, since.day, 8),
            route: Routes.loanDetail,
            arguments: loan.id,
            urgent: true,
          ),
        );
      }
    }
    if (dueCount > 0) {
      list.add(
        AppNotification(
          id: 'due-${_day.format(today)}',
          kind: NotificationKind.dueToday,
          title:
              'Hoy toca cobrar $dueCount ${dueCount == 1 ? 'cuota' : 'cuotas'}',
          body: 'Total del día: ${Formatters.currency2(dueAmount)}',
          date: DateTime(today.year, today.month, today.day, 7),
          route: Routes.collect,
        ),
      );
    }

    // ---- Préstamos saldados y nuevos ----
    final lastPayment = <String, DateTime>{};
    for (final p in _loans.payments) {
      final prev = lastPayment[p.loanId];
      if (prev == null || p.date.isAfter(prev)) lastPayment[p.loanId] = p.date;
    }
    for (final loan in _loans.loans) {
      final paidAt = lastPayment[loan.id];
      if (loan.isPaidOff && paidAt != null && paidAt.isAfter(since)) {
        list.add(
          AppNotification(
            id: 'paid-${loan.id}',
            kind: NotificationKind.paidOff,
            title: 'Préstamo ${loan.id} saldado',
            body:
                '${clientName(loan.clientId)} terminó de pagar '
                '${Formatters.currency2(loan.totalDue)}.',
            date: paidAt,
            route: Routes.loanDetail,
            arguments: loan.id,
          ),
        );
      }
      final created = loan.createdAt ?? loan.startDate;
      if (_manages &&
          created.isAfter(since) &&
          loan.createdByUid != null &&
          loan.createdByUid != me.uid) {
        list.add(
          AppNotification(
            id: 'loan-${loan.id}',
            kind: NotificationKind.newLoan,
            title: 'Nuevo préstamo ${loan.id}',
            body:
                '${loan.createdBy ?? 'Alguien'} le prestó '
                '${Formatters.currency2(loan.amount)} a ${clientName(loan.clientId)}.',
            date: created,
            route: Routes.loanDetail,
            arguments: loan.id,
          ),
        );
      }
    }

    // ---- Cuadre: fondo, revisión y olvidos (cobrador) ----
    for (final f in _closings.funds) {
      if (f.uid != me.uid || f.day != today) continue;
      list.add(
        AppNotification(
          id: 'fund-${f.id}-${f.amount}',
          kind: NotificationKind.fund,
          title: 'Tu fondo de hoy: ${Formatters.currency2(f.amount)}',
          body: 'Asignado por ${f.assignedBy}.',
          date: f.assignedAt,
          route: Routes.cashClosing,
        ),
      );
    }
    for (final c in _closings.closings) {
      if (c.day.isBefore(since)) continue;
      final balance = ClosingBalance.of(c.difference);
      final result = balance == ClosingBalance.even
          ? 'cuadrado'
          : '${balance.label.toLowerCase()} de ${Formatters.currency2(c.difference.abs())}';
      if (c.byUid == me.uid && c.status == ClosingStatus.approved) {
        list.add(
          AppNotification(
            id: 'reviewed-${c.id}',
            kind: NotificationKind.closingReviewed,
            title: 'Tu cuadre del ${_short.format(c.day)} fue revisado',
            body: '${c.reviewedBy ?? 'El administrador'} lo revisó · $result.',
            date: c.reviewedAt ?? c.createdAt,
            route: Routes.cashClosing,
          ),
        );
      }
      if (_manages && c.byUid != me.uid && c.status == ClosingStatus.pending) {
        list.add(
          AppNotification(
            id: 'pending-${c.id}',
            kind: NotificationKind.closingPending,
            title: 'Cuadre de ${c.byName} por revisar',
            body: 'Día ${_short.format(c.day)} · $result.',
            date: c.createdAt,
            route: Routes.cashClosing,
            urgent: balance == ClosingBalance.short,
          ),
        );
      }
    }

    // Días pasados con movimientos y sin cuadre.
    final people = <String, String>{
      me.uid: me.name,
      if (_manages)
        for (final p in _loans.payments)
          if (p.collectorUid != null) p.collectorUid!: p.collector,
    };
    for (var back = 1; back <= 3; back++) {
      final day = today.subtract(Duration(days: back));
      for (final e in people.entries) {
        if (_closings.of(e.key, day) != null) continue;
        final s = CashSummary.of(
          day: day,
          uid: e.key,
          name: e.value,
          payments: _loans.payments,
          loans: _loans.loans,
          expenses: _expenses.expenses,
        );
        if (s.isEmpty) continue;
        final mine = e.key == me.uid;
        list.add(
          AppNotification(
            id: 'missing-${e.key}-${_day.format(day)}',
            kind: NotificationKind.closingMissing,
            title: mine
                ? 'No cerraste el cuadre del ${_short.format(day)}'
                : '${e.value} no cerró el cuadre del ${_short.format(day)}',
            body:
                '${s.paymentsCount} cobros · efectivo '
                '${Formatters.currency2(s.cashIn)} sin cuadrar.',
            date: day.add(const Duration(hours: 20)),
            route: Routes.cashClosing,
            arguments: day,
            urgent: true,
          ),
        );
      }
    }

    return list;
  }
}
