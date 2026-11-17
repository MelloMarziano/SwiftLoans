import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/company.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/sources/company_data_source.dart';
import 'auth_service.dart';

/// Fuente de datos de la empresa del usuario en sesión. Cambia sola al
/// iniciar o cerrar sesión, así cada empresa solo ve lo suyo.
///
/// El ROOT no tiene empresa propia: usa la app con los datos de la empresa
/// que tenga elegida ([viewing]). Al entrar se elige la primera; luego la
/// cambia desde Ajustes → Empresas.
class CompanySession extends GetxService {
  CompanySession(this._factory);

  final CompanyDataSource Function(String companyId) _factory;

  final source = Rxn<CompanyDataSource>();

  /// Empresa que el ROOT está viendo (null = aún no hay empresas).
  final viewing = Rxn<Company>();

  String? _companyId;
  late final AuthService _auth;
  StreamSubscription<List<Company>>? _companiesSub;

  @override
  void onInit() {
    super.onInit();
    _auth = Get.find<AuthService>();
    _onUser();
    ever(_auth.user, (_) => _onUser());
    ever(viewing, (_) => _sync());
  }

  @override
  void onClose() {
    _companiesSub?.cancel();
    super.onClose();
  }

  void enter(Company company) => viewing.value = company;

  /// Vuelve a crear la fuente (p. ej. recargar los datos de ejemplo).
  void reload() {
    final id = _companyId;
    _companyId = null;
    source.value?.dispose();
    source.value = null;
    _switchTo(id);
  }

  void _onUser() {
    final isRoot = _auth.user.value?.isRoot ?? false;
    _companiesSub?.cancel();
    _companiesSub = null;
    if (!isRoot) {
      viewing.value = null;
    } else if (Get.isRegistered<AdminRepository>()) {
      // Mantiene al día la empresa elegida (nombre, estado) y elige la
      // primera si no hay ninguna o si la elegida se borró.
      _companiesSub = Get.find<AdminRepository>().watchCompanies().listen((
        list,
      ) {
        final current = viewing.value;
        viewing.value =
            list.firstWhereOrNull((c) => c.id == current?.id) ??
            list.firstWhereOrNull((c) => c.active) ??
            list.firstOrNull;
      });
    }
    _sync();
  }

  void _sync() => _switchTo(_auth.user.value?.companyId ?? viewing.value?.id);

  void _switchTo(String? companyId) {
    if (companyId == _companyId && source.value != null) return;
    source.value?.dispose();
    _companyId = companyId;
    source.value = companyId == null ? null : _factory(companyId);
  }
}
