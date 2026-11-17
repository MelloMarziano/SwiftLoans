import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/auth_backend.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';

class LoginController extends GetxController {
  final _auth = Get.find<AuthService>();

  late final identifier = TextEditingController(text: _auth.rememberedUsername);
  final password = TextEditingController();
  final passwordFocus = FocusNode();

  late final remember = _auth.rememberMe.obs;
  final obscure = true.obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onClose() {
    identifier.dispose();
    password.dispose();
    passwordFocus.dispose();
    super.onClose();
  }

  Future<void> signIn() async {
    if (identifier.text.trim().isEmpty || password.text.isEmpty) {
      error.value = 'Escribe tu usuario y contraseña.';
      return;
    }
    error.value = null;
    isLoading.value = true;
    try {
      final user = await _auth.signIn(
        identifier: identifier.text,
        password: password.text,
        remember: remember.value,
      );
      Get.offAllNamed(
        user.mustChangePassword ? Routes.changePassword : Routes.root,
      );
    } on AuthFailure catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'No se pudo iniciar sesión. Inténtalo de nuevo.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Entra a la demo con el rol elegido (dueño o cobrador).
  void startDemo(AppUser demoUser) {
    _auth.startDemo(demoUser);
    Get.offAllNamed(Routes.root);
  }

  Future<void> forgotPassword() async {
    final value = identifier.text.trim();

    // Los usuarios sin correo no pueden recibir el enlace.
    if (value.isEmpty || AuthService.isUsername(value)) {
      await ConfirmDialog.show(
        title: 'Restablecer contraseña',
        message: value.isEmpty
            ? 'Escribe tu correo en el campo de usuario y vuelve a tocar '
                  '"¿Olvidaste tu contraseña?".'
            : 'Tu usuario no tiene correo asociado. Pide al administrador '
                  'que restablezca tu contraseña.',
        confirmLabel: 'Entendido',
        showCancel: false,
        icon: LucideIcons.keyRound,
      );
      return;
    }

    try {
      await _auth.sendPasswordReset(value);
      Get.snackbar(
        'Revisa tu correo',
        'Te enviamos un enlace a $value para restablecer tu contraseña.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } on AuthFailure catch (e) {
      error.value = e.message;
    }
  }
}
