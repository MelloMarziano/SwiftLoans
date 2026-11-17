import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import 'auth_service.dart';

/// Datos del usuario en sesión que muestra la interfaz (nombre, iniciales,
/// rol). Se actualiza solo cuando cambia la sesión en [AuthService].
class SessionService extends GetxService {
  final userName = ''.obs;
  final userInitials = ''.obs;
  final role = Rxn<UserRole>();

  /// Notificaciones sin leer (lo actualiza NotificationService).
  final unreadNotifications = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthService>();
    _apply(auth.user.value);
    ever(auth.user, _apply);
  }

  void _apply(AppUser? user) {
    userName.value = user?.name ?? '';
    userInitials.value = user?.initials ?? '';
    role.value = user?.role;
  }
}
