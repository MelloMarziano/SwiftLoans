import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/demo_mode.dart';
import '../../core/services/session_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/settings_tile.dart';
import '../../routes/app_routes.dart';
import 'widgets/settings_page.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Get.find<SettingsService>();
    final user = Get.find<AuthService>().user.value;
    final isRoot = user?.isRoot ?? false;

    return SettingsPage(
      title: 'Ajustes',
      children: [
        const _ProfileCard(),
        if (isRoot)
          SettingsGroup(
            title: 'Plataforma (ROOT)',
            children: [
              SettingsTile(
                icon: LucideIcons.building2,
                title: 'Empresas',
                subtitle: 'Crea, suspende y elige con cuál trabajar',
                onTap: () => Get.toNamed(Routes.companies),
              ),
            ],
          ),
        if (user?.role.managesUsers ?? false)
          SettingsGroup(
            title: 'Empresa',
            children: [
              SettingsTile(
                icon: LucideIcons.users,
                title: 'Usuarios',
                subtitle: 'Crea y administra a tu equipo',
                onTap: () => Get.toNamed(Routes.team),
              ),
            ],
          ),
        Obx(
          () => SettingsGroup(
            title: 'Negocio',
            children: [
              SettingsTile(
                icon: LucideIcons.building2,
                title: 'Datos del negocio',
                subtitle: s.businessName.value,
                onTap: () => Get.toNamed(Routes.settingsBusiness),
              ),
              SettingsTile(
                icon: LucideIcons.slidersHorizontal,
                title: 'Préstamos por defecto',
                subtitle:
                    '${s.defaultRate.value.toStringAsFixed(0)}% mensual · '
                    'mora ${s.defaultLateFee.value.toStringAsFixed(0)}% · '
                    '${s.defaultInstallments.value} cuotas '
                    '${s.defaultFrequency.value.installmentsAdjective}',
                onTap: () => Get.toNamed(Routes.settingsLoans),
              ),
              SettingsTile(
                icon: LucideIcons.route,
                title: 'Rutas y oficinas',
                subtitle: s.routes.length == 1
                    ? '1 ruta'
                    : '${s.routes.length} rutas',
                onTap: () => Get.toNamed(Routes.settingsRoutes),
              ),
            ],
          ),
        ),
        Obx(
          () => SettingsGroup(
            title: 'Dispositivo',
            children: [
              SettingsTile(
                icon: LucideIcons.printer,
                title: 'Impresora',
                subtitle: s.printerType.value == PrinterType.none
                    ? s.printerType.value.label
                    : '${s.printerType.value.label} · ${s.paperWidth.value.label}',
                onTap: () => Get.toNamed(Routes.settingsPrinter),
              ),
            ],
          ),
        ),
        SettingsGroup(
          title: 'Mantenimiento',
          children: [
            SettingsTile(
              icon: LucideIcons.wrench,
              title: 'Datos y mantenimiento',
              subtitle: 'Restablecer ajustes y datos de ejemplo',
              onTap: () => Get.toNamed(Routes.settingsMaintenance),
            ),
            const _VersionTile(),
          ],
        ),
        const _AccountGroup(),
      ],
    );
  }
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup();

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: 'Cuenta',
      children: [
        if (!DemoMode.active)
          SettingsTile(
            icon: LucideIcons.keyRound,
            title: 'Cambiar contraseña',
            onTap: () => Get.toNamed(Routes.changePassword),
          ),
        const SettingsTile(
          icon: LucideIcons.logOut,
          title: 'Cerrar sesión',
          destructive: true,
          onTap: _signOut,
        ),
      ],
    );
  }
}

Future<void> _signOut() async {
  final ok = await ConfirmDialog.show(
    title: 'Cerrar sesión',
    message: '¿Quieres salir de tu cuenta en este dispositivo?',
    confirmLabel: 'Cerrar sesión',
    destructive: true,
    icon: LucideIcons.logOut,
  );
  if (!ok) return;
  await Get.find<AuthService>().signOut();
  Get.offAllNamed(Routes.login);
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    return SectionCard(
      child: Obx(
        () => Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.avatar,
              child: Text(
                session.userInitials.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.userName.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    session.role.value?.label ?? '',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return SettingsTile(
          icon: LucideIcons.info,
          title: 'Versión de la app',
          subtitle: info == null
              ? '—'
              : '${info.version} (compilación ${info.buildNumber})',
        );
      },
    );
  }
}
