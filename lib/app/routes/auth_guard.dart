import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/services/auth_service.dart';
import '../data/models/app_user.dart';
import 'app_routes.dart';

/// Sin sesión, cualquier pantalla protegida lleva al login. Con contraseña
/// temporal, obliga a cambiarla antes de seguir.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final user = Get.find<AuthService>().user.value;
    if (user == null) return const RouteSettings(name: Routes.login);
    if (user.mustChangePassword) {
      return const RouteSettings(name: Routes.changePassword);
    }
    return null;
  }
}

/// Restringe una pantalla a ciertos roles (además de exigir sesión).
class RoleGuard extends GetMiddleware {
  RoleGuard(this.allowed);

  final bool Function(AppUser user) allowed;

  @override
  RouteSettings? redirect(String? route) {
    final user = Get.find<AuthService>().user.value;
    if (user == null) return const RouteSettings(name: Routes.login);
    return allowed(user) ? null : const RouteSettings(name: Routes.root);
  }
}
