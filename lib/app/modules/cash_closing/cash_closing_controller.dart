import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/finance/cash_summary.dart';
import '../../core/services/auth_backend.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/company_session.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/app_user.dart';
import '../../data/models/cash_closing.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/closing_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/loan_repository.dart';

enum ClosingTab { mine, team }

/// Fila del equipo: el cuadre de un usuario en el día (o lo que falta).
class TeamRow {
  const TeamRow({
    required this.uid,
    required this.name,
    required this.summary,
    this.closing,
    this.fund,
  });

  final String uid;
  final String name;
  final CashSummary summary;
  final CashClosing? closing;
  final CashFund? fund;
}

/// Cuadre de caja: el usuario cuenta su efectivo al final del día y lo
/// compara con lo que debería tener. Dueño y administrador revisan los
/// cuadres del equipo.
class CashClosingController extends GetxController {
  final _loans = Get.find<LoanRepository>();
  final _expenses = Get.find<ExpenseRepository>();
  final _closings = Get.find<ClosingRepository>();
  final _auth = Get.find<AuthService>();

  final totalController = TextEditingController();
  final notesController = TextEditingController();

  late final day = _dateOnly(_loans.today).obs;
  final tab = ClosingTab.mine.obs;

  /// true = contar billete por billete; false = escribir el total.
  final byDenomination = true.obs;
  final counts = <int, int>{}.obs;
  final typedTotal = 0.0.obs;
  final isSaving = false.obs;

  /// Usuarios activos de la empresa (para asignar fondos aunque aún no
  /// tengan movimientos). Solo lo cargan dueño/administrador/ROOT.
  final _users = <AppUser>[].obs;
  StreamSubscription<List<AppUser>>? _usersSub;

  /// Cambia con cada dato nuevo para recalcular la vista.
  final _version = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Desde una notificación puede llegar el día a revisar.
    if (Get.arguments is DateTime) changeDay(Get.arguments as DateTime);
    _loadUsers();
    totalController.addListener(
      () => typedTotal.value = MoneyInputFormatter.parse(totalController.text),
    );
    everAll([
      _loans.payments,
      _loans.loans,
      _expenses.expenses,
      _closings.closings,
      _closings.funds,
      _users,
      day,
    ], (_) => _version.value++);
  }

  void _loadUsers() {
    if (!canReview || !Get.isRegistered<AdminRepository>()) return;
    final companyId =
        me?.companyId ?? Get.find<CompanySession>().viewing.value?.id;
    if (companyId == null) return;
    _usersSub = Get.find<AdminRepository>()
        .watchUsers(companyId)
        .listen(_users.assignAll, onError: (_) {});
  }

  @override
  void onClose() {
    _usersSub?.cancel();
    totalController.dispose();
    notesController.dispose();
    super.onClose();
  }

  /// Registra la dependencia con los datos (usar dentro de Obx).
  void watch() => _version.value;

  AppUser? get me => _auth.user.value;
  bool get canReview => _closings.canReview;
  DateTime get today => _dateOnly(_loans.today);
  bool get isToday => day.value == today;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void changeDay(DateTime value) {
    final d = _dateOnly(value);
    if (d.isAfter(today)) return;
    day.value = d;
  }

  void previousDay() => changeDay(day.value.subtract(const Duration(days: 1)));
  void nextDay() => changeDay(day.value.add(const Duration(days: 1)));

  CashSummary summaryFor(String uid, String name) => CashSummary.of(
    day: day.value,
    uid: uid,
    name: name,
    payments: _loans.allPayments,
    loans: _loans.loans,
    expenses: _expenses.expenses,
  );

  // ---------- Mi cuadre ----------

  CashSummary get mySummary => summaryFor(me?.uid ?? '', me?.name ?? '');

  CashClosing? get myClosing =>
      me == null ? null : _closings.of(me!.uid, day.value);

  /// Fondo que el dueño/administrador asignó (null = ninguno).
  CashFund? get myFund =>
      me == null ? null : _closings.fundOf(me!.uid, day.value);

  double get opening => myFund?.amount ?? 0;

  double get expected => opening + mySummary.netCash;

  double get counted => byDenomination.value
      ? counts.entries.fold(0.0, (s, e) => s + e.key * e.value)
      : typedTotal.value;

  double get difference => ((counted - expected) * 100).roundToDouble() / 100;

  void setCount(int denomination, int quantity) =>
      counts[denomination] = quantity < 0 ? 0 : quantity;

  /// Si ya cerró, los movimientos del día cambiaron después del cuadre.
  bool get changedAfterClosing {
    final c = myClosing;
    if (c == null) return false;
    final s = mySummary;
    return (s.cashIn - c.cashIn).abs() > 0.009 ||
        (s.cashLoans - c.cashLoans).abs() > 0.009 ||
        (s.cashExpenses - c.cashExpenses).abs() > 0.009;
  }

  Future<CashClosing?> close() async {
    final user = me;
    if (user == null) return null;
    final s = mySummary;
    final diff = difference;
    final balance = ClosingBalance.of(diff);

    final ok = await ConfirmDialog.show(
      title: 'Cerrar cuadre',
      message:
          'Esperado ${Formatters.currency2(expected)} · contado '
          '${Formatters.currency2(counted)}.\n'
          '${balance == ClosingBalance.even ? 'La caja está cuadrada.' : '${balance.label} de ${Formatters.currency2(diff.abs())}.'}'
          '\n\nUna vez cerrado no se puede cambiar.',
      confirmLabel: 'Cerrar cuadre',
      icon: LucideIcons.clipboardCheck,
    );
    if (!ok) return null;

    final closing = CashClosing(
      id: CashClosing.idFor(user.uid, day.value),
      day: day.value,
      byUid: user.uid,
      byName: user.name,
      openingCash: opening,
      cashIn: s.cashIn,
      transferIn: s.transferIn,
      cashLoans: s.cashLoans,
      cashExpenses: s.cashExpenses,
      counted: counted,
      paymentsCount: s.paymentsCount,
      denominations: byDenomination.value ? Map.of(counts) : const {},
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      createdAt: DateTime.now(),
    );
    isSaving.value = true;
    try {
      await _closings.add(closing);
      return closing;
    } on AuthFailure catch (e) {
      Get.snackbar(
        'No se pudo cerrar el cuadre',
        e.message,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  // ---------- Equipo ----------

  /// Cada usuario con movimientos o cuadre en el día; los que faltan por
  /// cuadrar primero.
  List<TeamRow> get team {
    final people = <String, String>{};
    final d = day.value;
    final to = d.add(const Duration(days: 1));
    bool inDay(DateTime x) => !x.isBefore(d) && x.isBefore(to);

    for (final p in _loans.allPayments) {
      if (inDay(p.date) && p.collectorUid != null) {
        people[p.collectorUid!] = p.collector;
      }
    }
    for (final l in _loans.loans) {
      if (inDay(l.createdAt ?? l.startDate) && l.createdByUid != null) {
        people[l.createdByUid!] = l.createdBy ?? '';
      }
    }
    for (final e in _expenses.expenses) {
      if (inDay(e.date)) people[e.byUid] = e.byName;
    }
    for (final c in _closings.closings) {
      if (c.day == d) people[c.byUid] = c.byName;
    }
    for (final f in _closings.funds) {
      if (f.day == d) people[f.uid] = f.name;
    }
    // Usuarios activos que aún no se mueven hoy (para asignarles fondo).
    if (d == today) {
      for (final u in _users) {
        if (u.active && u.role != UserRole.owner) {
          people.putIfAbsent(u.uid, () => u.name);
        }
      }
    }

    final rows = [
      for (final e in people.entries)
        TeamRow(
          uid: e.key,
          name: e.value.isEmpty ? 'Sin nombre' : e.value,
          summary: summaryFor(e.key, e.value),
          closing: _closings.of(e.key, d),
          fund: _closings.fundOf(e.key, d),
        ),
    ];
    int rank(TeamRow r) => r.closing == null
        ? 0
        : r.closing!.status == ClosingStatus.pending
        ? 1
        : 2;
    rows.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.name.compareTo(b.name);
    });
    return rows;
  }

  int get pendingReviewCount =>
      team.where((r) => r.closing?.status == ClosingStatus.pending).length;

  Future<void> approve(CashClosing closing) => _closings.approve(closing);

  Future<void> assignFund(String uid, String name, double amount) =>
      _closings.setFund(uid: uid, name: name, day: day.value, amount: amount);
}
