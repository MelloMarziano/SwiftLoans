import 'dart:async';

import 'package:get/get.dart';

import '../../core/services/auth_backend.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/company_session.dart';
import '../models/app_user.dart';
import '../models/cash_closing.dart';
import '../sources/company_data_source.dart';

/// Cuadres de caja de la empresa en sesión.
class ClosingRepository extends GetxService {
  final _session = Get.find<CompanySession>();
  final _auth = Get.find<AuthService>();

  final _stored = <CashClosing>[].obs;
  final _pending = <String, CashClosing>{};

  /// Todos los cuadres (incluidos los aún sin subir).
  final closings = <CashClosing>[].obs;

  /// Fondos iniciales asignados.
  final funds = <CashFund>[].obs;

  StreamSubscription<List<CashClosing>>? _sub;
  StreamSubscription<List<CashFund>>? _fundsSub;

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
    _fundsSub?.cancel();
    super.onClose();
  }

  void _refresh() {
    for (final c in _stored) {
      _pending.remove(c.id);
    }
    closings.assignAll([..._stored, ..._pending.values]);
  }

  void _bind(CompanyDataSource? source) {
    _sub?.cancel();
    _fundsSub?.cancel();
    _pending.clear();
    _stored.clear();
    funds.clear();
    if (source != null) {
      _sub = source.watchClosings().listen(_stored.assignAll);
      _fundsSub = source.watchFunds().listen(funds.assignAll);
    }
  }

  /// Dueño, administrador y ROOT revisan cuadres.
  bool get canReview {
    final role = _auth.user.value?.role;
    return role == UserRole.root || (role?.managesUsers ?? false);
  }

  CashClosing? byId(String id) => closings.firstWhereOrNull((c) => c.id == id);

  CashClosing? of(String uid, DateTime day) =>
      byId(CashClosing.idFor(uid, day));

  Future<void> add(CashClosing closing) async {
    final source = _source;
    if (source == null) {
      throw const AuthFailure('No hay una empresa activa en esta sesión.');
    }
    if (byId(closing.id) != null) {
      throw const AuthFailure('Ya cerraste el cuadre de ese día.');
    }
    _pending[closing.id] = closing;
    _refresh();
    await source.addClosing(closing);
  }

  CashFund? fundOf(String uid, DateTime day) =>
      funds.firstWhereOrNull((f) => f.id == CashFund.idFor(uid, day));

  /// Dueño/administrador asigna el fondo inicial de un usuario para un día.
  Future<void> setFund({
    required String uid,
    required String name,
    required DateTime day,
    required double amount,
  }) async {
    final source = _source;
    final me = _auth.user.value;
    if (source == null || me == null) return;
    if (!canReview) {
      throw const AuthFailure(
        'Solo el dueño o el administrador asignan fondos.',
      );
    }
    if (of(uid, day) != null) {
      throw AuthFailure('$name ya cerró el cuadre de ese día.');
    }
    final fund = CashFund(
      id: CashFund.idFor(uid, day),
      day: DateTime(day.year, day.month, day.day),
      uid: uid,
      name: name,
      amount: amount,
      assignedBy: me.name,
      assignedAt: DateTime.now(),
    );
    final i = funds.indexWhere((f) => f.id == fund.id);
    if (i == -1) {
      funds.add(fund);
    } else {
      funds[i] = fund;
    }
    await source.setFund(fund);
  }

  Future<void> approve(CashClosing closing) async {
    final source = _source;
    final me = _auth.user.value;
    if (source == null || me == null) return;
    await source.approveClosing(closing.id, me.name);
  }
}
