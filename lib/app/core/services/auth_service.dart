import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import 'auth_backend.dart';
import 'key_value_store.dart';

/// Sesión del usuario. Se entra con usuario (p. ej. "root") o con correo.
class AuthService extends GetxService {
  AuthService({required AuthBackend backend, required KeyValueStore store})
    : _backend = backend,
      _store = store;

  /// Los usuarios sin correo (cobradores, ROOT) se guardan en Firebase con
  /// este dominio: "root" -> root@swiftloans-app.firebaseapp.com.
  static const usernameDomain = 'swiftloans-app.firebaseapp.com';

  final AuthBackend _backend;
  final KeyValueStore _store;

  final user = Rxn<AppUser>();

  bool get isLoggedIn => user.value != null;

  /// Último usuario recordado (para llenar el campo en el login).
  String get rememberedUsername => _store.read<String>('auth.username') ?? '';
  bool get rememberMe => _store.read<bool>('auth.remember') ?? true;

  static String emailFor(String identifier) {
    final value = identifier.trim().toLowerCase();
    return value.contains('@') ? value : '$value@$usernameDomain';
  }

  static bool isUsername(String identifier) => !identifier.contains('@');

  /// Al abrir la app: recupera la sesión guardada (si el usuario marcó
  /// "Recordarme" y sigue habilitado).
  Future<void> restore() async {
    final uid = _backend.currentUid;
    if (uid == null) return;
    if (!rememberMe) {
      await _backend.signOut();
      return;
    }
    try {
      final profile = await _backend.loadProfile(uid);
      if (profile == null || !profile.active || !await _companyOk(profile)) {
        await _backend.signOut();
        return;
      }
      user.value = profile;
    } catch (_) {
      // Sin perfil disponible (ni en caché): se pide iniciar sesión.
      await _backend.signOut();
    }
  }

  Future<AppUser> signIn({
    required String identifier,
    required String password,
    required bool remember,
  }) async {
    final uid = await _backend.signIn(emailFor(identifier), password);
    final profile = await _backend.loadProfile(uid);

    if (profile == null || !profile.active) {
      await _backend.signOut();
      throw const AuthFailure(
        'Tu usuario no está habilitado. Contacta al administrador.',
      );
    }
    if (!await _companyOk(profile)) {
      await _backend.signOut();
      throw const AuthFailure(
        'Tu empresa está suspendida. Contacta a SwiftLoans.',
      );
    }

    _store.write('auth.remember', remember);
    _store.write('auth.username', remember ? identifier.trim() : '');
    user.value = profile;
    return profile;
  }

  /// El ROOT no pertenece a ninguna empresa; los demás necesitan la suya activa.
  Future<bool> _companyOk(AppUser profile) async =>
      profile.isRoot ||
      (profile.companyId != null &&
          await _backend.isCompanyActive(profile.companyId!));

  /// Entra al modo demo (sin cuenta, datos de ejemplo). No se recuerda al
  /// volver a abrir la app.
  void startDemo(AppUser demoUser) => user.value = demoUser;

  Future<void> signOut() async {
    await _backend.signOut();
    user.value = null;
  }

  Future<void> sendPasswordReset(String email) =>
      _backend.sendPasswordReset(email.trim());

  Future<void> changePassword(String current, String next) async {
    await _backend.changePassword(current, next);
    final u = user.value;
    if (u != null && u.mustChangePassword) {
      await _backend.clearMustChangePassword(u.uid);
      user.value = u.copyWith(mustChangePassword: false);
    }
  }
}
