import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/auth_backend.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/form/form_fields.dart';
import '../../core/widgets/section_card.dart';
import '../../routes/app_routes.dart';

class ChangePasswordController extends GetxController {
  final _auth = Get.find<AuthService>();

  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  final errors = <String, String>{}.obs;
  final isSaving = false.obs;

  /// Si viene de una contraseña temporal no puede saltarse este paso.
  bool get isForced => _auth.user.value?.mustChangePassword ?? false;

  static const minLength = 8;

  @override
  void onClose() {
    for (final c in [current, next, confirm]) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> save() async {
    errors.assignAll({
      if (current.text.isEmpty) 'current': 'Escribe tu contraseña actual',
      if (next.text.length < minLength) 'next': 'Mínimo $minLength caracteres',
      if (next.text == current.text && next.text.isNotEmpty)
        'next': 'Debe ser distinta a la actual',
      if (confirm.text != next.text) 'confirm': 'Las contraseñas no coinciden',
    });
    if (errors.isNotEmpty) return;

    isSaving.value = true;
    try {
      await _auth.changePassword(current.text, next.text);
      Get.offAllNamed(Routes.root);
      Get.snackbar(
        'Contraseña actualizada',
        'Usa tu nueva contraseña la próxima vez que entres.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } on AuthFailure catch (e) {
      errors['current'] = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    Get.offAllNamed(Routes.login);
  }
}

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());
    final forced = controller.isForced;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: !forced,
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (forced)
            TextButton(
              onPressed: controller.signOut,
              child: const Text('Salir'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (forced)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.tile,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Estás usando una contraseña temporal. Crea una '
                            'nueva para continuar.',
                          ),
                        ),
                      ],
                    ),
                  ),
                SectionCard(
                  child: Obx(
                    () => Column(
                      children: [
                        TextFieldBox(
                          icon: LucideIcons.lock,
                          label: 'Contraseña actual',
                          controller: controller.current,
                          keyboardType: TextInputType.visiblePassword,
                          obscure: true,
                          error: controller.errors['current'],
                        ),
                        const SizedBox(height: 10),
                        TextFieldBox(
                          icon: LucideIcons.keyRound,
                          label: 'Nueva contraseña',
                          hint:
                              'Mínimo ${ChangePasswordController.minLength} caracteres',
                          controller: controller.next,
                          keyboardType: TextInputType.visiblePassword,
                          obscure: true,
                          error: controller.errors['next'],
                        ),
                        const SizedBox(height: 10),
                        TextFieldBox(
                          icon: LucideIcons.keyRound,
                          label: 'Confirmar nueva contraseña',
                          controller: controller.confirm,
                          keyboardType: TextInputType.visiblePassword,
                          obscure: true,
                          textInputAction: TextInputAction.done,
                          error: controller.errors['confirm'],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => FilledButton.icon(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.save,
                    icon: controller.isSaving.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.save, size: 20),
                    label: const Text('Guardar contraseña'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
