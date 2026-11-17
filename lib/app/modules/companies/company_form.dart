import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/auth_backend.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/utils/user_validators.dart';
import '../../core/widgets/form/form_fields.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../data/models/app_user.dart';
import '../../data/models/company.dart';
import '../../data/repositories/admin_repository.dart';
import '../settings/widgets/settings_page.dart';

class CompanyFormController extends GetxController {
  final _repo = Get.find<AdminRepository>();

  final name = TextEditingController();
  final rnc = TextEditingController();
  final phone = TextEditingController();
  final maxUsers = TextEditingController(text: '5');
  final ownerName = TextEditingController();
  final ownerUsername = TextEditingController();
  final ownerPassword = TextEditingController();

  final errors = <String, String>{}.obs;
  final isSaving = false.obs;

  @override
  void onClose() {
    for (final c in [
      name,
      rnc,
      phone,
      maxUsers,
      ownerName,
      ownerUsername,
      ownerPassword,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> save() async {
    if (isSaving.value) return;
    final seats = int.tryParse(maxUsers.text) ?? 0;
    errors.assignAll({
      if (name.text.trim().length < 2)
        'name': 'Escribe el nombre de la empresa',
      if (seats < 1) 'maxUsers': 'Mínimo 1',
      'ownerName': ?UserValidators.name(ownerName.text),
      'ownerUsername': ?UserValidators.username(ownerUsername.text),
      'ownerPassword': ?UserValidators.password(ownerPassword.text),
    });
    if (errors.isNotEmpty) return;

    isSaving.value = true;
    try {
      String? clean(TextEditingController c) =>
          c.text.trim().isEmpty ? null : c.text.trim();

      final company = await _repo.createCompany(
        name: name.text.trim(),
        rnc: clean(rnc),
        phone: clean(phone),
        maxUsers: seats,
        owner: NewUser(
          username: ownerUsername.text.trim().toLowerCase(),
          name: ownerName.text.trim(),
          password: ownerPassword.text,
          role: UserRole.owner,
        ),
      );
      Get.back();
      Get.snackbar(
        'Empresa creada',
        '${company.name}. El dueño entra con el usuario '
            '"${ownerUsername.text.trim().toLowerCase()}" y deberá cambiar su '
            'contraseña la primera vez.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
      );
    } on AuthFailure catch (e) {
      errors['ownerUsername'] = e.message;
    } catch (e) {
      Get.snackbar(
        'No se pudo crear la empresa',
        '$e',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSaving.value = false;
    }
  }
}

class CompanyFormView extends GetView<CompanyFormController> {
  const CompanyFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SettingsPage(
        title: 'Nueva empresa',
        saveLabel: controller.isSaving.value ? 'Creando...' : 'Crear empresa',
        onSave: controller.save,
        children: [
          FormSectionCard(
            icon: LucideIcons.building2,
            title: 'Empresa',
            child: Column(
              children: [
                TextFieldBox(
                  icon: LucideIcons.store,
                  label: 'Nombre de la empresa',
                  required: true,
                  controller: controller.name,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  error: controller.errors['name'],
                ),
                const SizedBox(height: 10),
                FieldGrid(
                  children: [
                    TextFieldBox(
                      icon: LucideIcons.idCard,
                      label: 'RNC',
                      hint: 'Opcional',
                      controller: controller.rnc,
                      keyboardType: TextInputType.number,
                    ),
                    TextFieldBox(
                      icon: LucideIcons.phone,
                      label: 'Teléfono',
                      hint: 'Opcional',
                      controller: controller.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [MaskedDigitsFormatter.phone()],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFieldBox(
                  icon: LucideIcons.users,
                  label: 'Límite de usuarios',
                  required: true,
                  controller: controller.maxUsers,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  error: controller.errors['maxUsers'],
                ),
                const SizedBox(height: 8),
                const _Hint(
                  'Incluye al dueño. La empresa no podrá crear más usuarios que '
                  'este límite; solo tú puedes cambiarlo.',
                ),
              ],
            ),
          ),
          FormSectionCard(
            icon: LucideIcons.userRound,
            title: 'Usuario dueño',
            child: Column(
              children: [
                TextFieldBox(
                  icon: LucideIcons.user,
                  label: 'Nombre del dueño',
                  required: true,
                  controller: controller.ownerName,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  error: controller.errors['ownerName'],
                ),
                const SizedBox(height: 10),
                FieldGrid(
                  children: [
                    TextFieldBox(
                      icon: LucideIcons.atSign,
                      label: 'Usuario',
                      required: true,
                      hint: 'ej. juanperez',
                      controller: controller.ownerUsername,
                      keyboardType: TextInputType.visiblePassword,
                      error: controller.errors['ownerUsername'],
                    ),
                    TextFieldBox(
                      icon: LucideIcons.keyRound,
                      label: 'Contraseña temporal',
                      required: true,
                      hint: 'Mínimo 6',
                      controller: controller.ownerPassword,
                      keyboardType: TextInputType.visiblePassword,
                      error: controller.errors['ownerPassword'],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _Hint(
                  'Entrégale estos datos al dueño. Al entrar por primera vez '
                  'la app le pedirá cambiar la contraseña.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.info, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}
