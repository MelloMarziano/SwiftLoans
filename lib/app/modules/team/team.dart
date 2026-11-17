import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/auth_backend.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/user_validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form/form_fields.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../core/widgets/settings_tile.dart';
import '../../data/models/app_user.dart';
import '../../data/models/company.dart';
import '../../data/repositories/admin_repository.dart';
import '../../routes/app_routes.dart';
import '../companies/widgets/user_tile.dart';
import '../settings/widgets/settings_page.dart';

/// Empleados de la empresa del usuario (solo dueño y administrador).
class TeamController extends GetxController {
  final _repo = Get.find<AdminRepository>();
  final AppUser me = Get.find<AuthService>().user.value!;

  final company = Rxn<Company>();
  final users = <AppUser>[].obs;

  String get companyId => me.companyId!;

  @override
  void onInit() {
    super.onInit();
    company.bindStream(_repo.watchCompany(companyId));
    users.bindStream(_repo.watchUsers(companyId));
  }

  /// Solo se gestionan los roles que uno puede crear (nunca al dueño ni a
  /// uno mismo).
  bool canManage(AppUser u) =>
      u.uid != me.uid && me.role.canCreate.contains(u.role);

  void newUser() {
    final c = company.value;
    if (c != null && !c.hasFreeSeats) {
      ConfirmDialog.show(
        title: 'Límite alcanzado',
        message:
            'Tu empresa ya usa sus ${c.maxUsers} usuarios. Para agregar más, '
            'contacta a SwiftLoans.',
        confirmLabel: 'Entendido',
        showCancel: false,
        icon: LucideIcons.users,
      );
      return;
    }
    Get.toNamed(Routes.teamNew);
  }

  Future<void> toggle(AppUser u) async {
    final deactivate = u.active;
    final ok = await ConfirmDialog.show(
      title: deactivate ? 'Desactivar usuario' : 'Activar usuario',
      message: deactivate
          ? '${u.name} no podrá entrar a la app. Su cupo sigue ocupado.'
          : '${u.name} podrá volver a entrar.',
      confirmLabel: deactivate ? 'Desactivar' : 'Activar',
      destructive: deactivate,
      icon: deactivate ? LucideIcons.userX : LucideIcons.userCheck,
    );
    if (ok) await _repo.setUserActive(u.uid, active: !deactivate);
  }
}

class TeamView extends GetView<TeamController> {
  const TeamView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Usuarios',
      children: [
        Obx(() {
          final c = controller.company.value;
          if (c == null) return const LinearProgressIndicator();
          final ratio = c.maxUsers == 0 ? 1.0 : c.userCount / c.maxUsers;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.userCount} de ${c.maxUsers} usuarios'
                  '${c.hasFreeSeats ? ' · ${c.freeSeats} disponibles' : ' · límite alcanzado'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: AppColors.tile,
                    color: c.hasFreeSeats
                        ? AppColors.primary
                        : const Color(0xFFB7791F),
                  ),
                ),
              ],
            ),
          );
        }),
        Obx(
          () => SettingsGroup(
            title: 'Equipo',
            children: [
              for (final u in controller.users)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: UserTile(
                    user: u,
                    onToggle: controller.canManage(u)
                        ? () => controller.toggle(u)
                        : null,
                  ),
                ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: controller.newUser,
          icon: const Icon(LucideIcons.userPlus, size: 20),
          label: const Text('Nuevo usuario'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size.fromHeight(50),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class NewUserController extends GetxController {
  final _repo = Get.find<AdminRepository>();
  final AppUser me = Get.find<AuthService>().user.value!;

  final name = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  late final role = me.role.canCreate.last.obs;

  final errors = <String, String>{}.obs;
  final isSaving = false.obs;

  @override
  void onClose() {
    for (final c in [name, username, password]) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> save() async {
    if (isSaving.value) return;
    errors.assignAll({
      'name': ?UserValidators.name(name.text),
      'username': ?UserValidators.username(username.text),
      'password': ?UserValidators.password(password.text),
    });
    if (errors.isNotEmpty) return;

    isSaving.value = true;
    try {
      final user = await _repo.createUser(
        companyId: me.companyId!,
        user: NewUser(
          username: username.text.trim().toLowerCase(),
          name: name.text.trim(),
          password: password.text,
          role: role.value,
        ),
      );
      Get.back();
      Get.snackbar(
        'Usuario creado',
        '${user.name} entra con "${user.username}" y deberá cambiar su '
            'contraseña la primera vez.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      );
    } on AuthFailure catch (e) {
      errors['username'] = e.message;
    } finally {
      isSaving.value = false;
    }
  }
}

class NewUserView extends GetView<NewUserController> {
  const NewUserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SettingsPage(
        title: 'Nuevo usuario',
        saveLabel: controller.isSaving.value ? 'Creando...' : 'Crear usuario',
        onSave: controller.save,
        children: [
          FormSectionCard(
            icon: LucideIcons.userPlus,
            title: 'Datos del usuario',
            child: Column(
              children: [
                TextFieldBox(
                  icon: LucideIcons.user,
                  label: 'Nombre completo',
                  required: true,
                  controller: controller.name,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  error: controller.errors['name'],
                ),
                const SizedBox(height: 10),
                FieldGrid(
                  children: [
                    TextFieldBox(
                      icon: LucideIcons.atSign,
                      label: 'Usuario',
                      required: true,
                      hint: 'ej. pedro',
                      controller: controller.username,
                      keyboardType: TextInputType.visiblePassword,
                      error: controller.errors['username'],
                    ),
                    TextFieldBox(
                      icon: LucideIcons.keyRound,
                      label: 'Contraseña temporal',
                      required: true,
                      hint: 'Mínimo 6',
                      controller: controller.password,
                      keyboardType: TextInputType.visiblePassword,
                      error: controller.errors['password'],
                    ),
                  ],
                ),
                if (controller.me.role.canCreate.length > 1) ...[
                  const SizedBox(height: 10),
                  SelectFieldBox<UserRole>(
                    icon: LucideIcons.shieldCheck,
                    label: 'Rol',
                    value: controller.role.value,
                    options: controller.me.role.canCreate,
                    optionLabel: (r) => r.label,
                    onChanged: (r) => controller.role.value = r,
                  ),
                ],
              ],
            ),
          ),
          const _RolesHelp(),
        ],
      ),
    );
  }
}

class _RolesHelp extends StatelessWidget {
  const _RolesHelp();

  @override
  Widget build(BuildContext context) {
    return const SettingsGroup(
      title: 'Roles',
      children: [
        SettingsTile(
          icon: LucideIcons.shieldCheck,
          title: 'Administrador',
          subtitle: 'Usa la app y puede crear cobradores.',
        ),
        SettingsTile(
          icon: LucideIcons.banknote,
          title: 'Cobrador',
          subtitle: 'Usa la app para cobrar; no crea usuarios.',
        ),
      ],
    );
  }
}
