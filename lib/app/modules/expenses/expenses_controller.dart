import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/date_period.dart';
import '../../data/models/app_user.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import 'widgets/expense_detail_sheet.dart';
import 'widgets/expense_form_sheet.dart';

/// Gastos por periodo. El cobrador solo ve los suyos; dueño, administrador y
/// ROOT ven todos.
class ExpensesController extends GetxController {
  final _repo = Get.find<ExpenseRepository>();
  final _auth = Get.find<AuthService>();

  final period = DatePeriod.today.obs;
  final customRange = Rxn<DateTimeRange>();
  final categories = <ExpenseCategory>{}.obs;

  /// Gastos del periodo, más recientes primero.
  final visible = <Expense>[].obs;

  DateTime get today => _repo.today;

  bool get onlyMine => _auth.user.value?.role == UserRole.collector;
  bool get canDelete => _repo.canDelete;

  @override
  void onInit() {
    super.onInit();
    _apply();
    everAll([_repo.expenses, period, customRange, categories], (_) => _apply());
  }

  Iterable<Expense> get _mine {
    final uid = _auth.user.value?.uid;
    return onlyMine
        ? _repo.expenses.where((e) => e.byUid == uid)
        : _repo.expenses;
  }

  void _apply() {
    final now = today;
    visible.assignAll(
      _mine
          .where((e) => period.value.contains(e.date, now, customRange.value))
          .where((e) => categories.isEmpty || categories.contains(e.category))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  double get total => visible.fold(0, (s, e) => s + e.amount);

  /// Total por categoría, de mayor a menor.
  List<(ExpenseCategory, double)> get byCategory {
    final map = <ExpenseCategory, double>{};
    for (final e in visible) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return [for (final e in map.entries) (e.key, e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
  }

  void toggleCategory(ExpenseCategory c) =>
      categories.contains(c) ? categories.remove(c) : categories.add(c);

  Future<void> addExpense() => ExpenseFormSheet.show();

  void open(Expense e) => ExpenseDetailSheet.show(e);
}
