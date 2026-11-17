import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/sources/company_data_source.dart';
import 'auth_service.dart';
import 'company_session.dart';
import 'demo_mode.dart';
import 'settings_service.dart';

/// Mantiene los ajustes de la empresa en sesión al día: los carga al entrar
/// (o al cambiar de empresa) y guarda los cambios del dueño/administrador
/// para que todos los usuarios de la empresa los vean.
class CompanySettingsSync extends GetxService {
  final _settings = Get.find<SettingsService>();
  final _session = Get.find<CompanySession>();

  StreamSubscription<Map<String, dynamic>?>? _sub;

  /// Solo dueño, administrador y ROOT cambian los ajustes de la empresa.
  static bool get canEdit {
    final role = Get.find<AuthService>().user.value?.role;
    return role == UserRole.root || (role?.managesUsers ?? false);
  }

  @override
  void onInit() {
    super.onInit();
    _settings.onCompanyChanged = _save;
    _bind(_session.source.value);
    ever(_session.source, _bind);
  }

  @override
  void onClose() {
    _sub?.cancel();
    if (_settings.onCompanyChanged == _save) _settings.onCompanyChanged = null;
    super.onClose();
  }

  void _bind(CompanyDataSource? source) {
    _sub?.cancel();
    _settings.applyCompany(null);
    if (source == null) return;
    _sub = source.watchSettings().listen((data) {
      if (data != null) {
        _settings.applyCompany(data);
        return;
      }
      // La empresa aún no tiene ajustes: si este teléfono tenía los de
      // antes (se guardaban por dispositivo), el dueño/admin los sube.
      final legacy = _settings.legacyCompany;
      if (legacy != null && canEdit && !DemoMode.active) {
        _settings.applyCompany(legacy);
        source.saveSettings(_settings.companyMap());
        _settings.clearLegacyCompany();
      }
    }, onError: (_) {});
  }

  void _save(Map<String, dynamic> data) {
    if (!canEdit) return;
    _session.source.value?.saveSettings(data);
  }
}
