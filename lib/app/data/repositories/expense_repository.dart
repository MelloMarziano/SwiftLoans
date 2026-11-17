import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/services/auth_backend.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/company_session.dart';
import '../models/app_user.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import '../sources/company_data_source.dart';

/// Gastos de la empresa en sesión. Se registran sin conexión y solo el
/// dueño, el administrador o el ROOT pueden borrarlos.
class ExpenseRepository extends GetxService {
  final _session = Get.find<CompanySession>();
  final _auth = Get.find<AuthService>();

  final _stored = <Expense>[].obs;

  /// Recién registrados que aún no llegan por el stream.
  final _pending = <String, Expense>{};

  /// Todos los gastos (incluidos los pendientes de subir).
  final expenses = <Expense>[].obs;

  StreamSubscription<List<Expense>>? _sub;

  DateTime get today => DateTime.now();

  CompanyDataSource? get _source => _session.source.value;

  @override
  void onInit() {
    super.onInit();
    _bind(_source);
    ever(_session.source, _bind);
    ever(_stored, (_) => _refresh());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _refresh() {
    for (final e in _stored) {
      _pending.remove(e.id);
    }
    expenses.assignAll([..._stored, ..._pending.values]);
  }

  void _bind(CompanyDataSource? source) {
    _sub?.cancel();
    _pending.clear();
    _stored.clear();
    if (source != null) _sub = source.watchExpenses().listen(_stored.assignAll);
  }

  /// Dueño, administrador y ROOT pueden borrar gastos.
  bool get canDelete {
    final role = _auth.user.value?.role;
    return role == UserRole.root || (role?.managesUsers ?? false);
  }

  Future<Expense> add({
    required double amount,
    required ExpenseCategory category,
    required PaymentMethod method,
    String? description,
  }) async {
    final me = _auth.user.value;
    final source = _source;
    if (me == null || source == null) {
      throw const AuthFailure('No hay una empresa activa en esta sesión.');
    }
    final now = today;
    final expense = Expense(
      id: _newId(now),
      date: now,
      amount: amount,
      category: category,
      method: method,
      byUid: me.uid,
      byName: me.name,
      description: description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
    );
    _pending[expense.id] = expense;
    _refresh();
    await source.addExpense(expense);
    return expense;
  }

  Future<void> delete(Expense expense) async {
    final source = _source;
    if (source == null) return;
    _pending.remove(expense.id);
    _refresh();
    await source.deleteExpense(expense.id);
  }

  static final _random = Random();
  static String _newId(DateTime now) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(
      3,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return 'G-${DateFormat('yyMMdd-HHmm').format(now)}-$suffix';
  }
}
