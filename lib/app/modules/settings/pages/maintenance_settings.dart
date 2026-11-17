import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/company_settings_sync.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/repositories/loan_repository.dart';
import '../widgets/settings_page.dart';

class MaintenanceSettingsView extends StatelessWidget {
  const MaintenanceSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final clients = Get.find<ClientRepository>();
    final loans = Get.find<LoanRepository>();
    final settings = Get.find<SettingsService>();

    Future<void> resetPrinter() async {
      final ok = await ConfirmDialog.show(
        title: 'Restablecer impresora',
        message:
            'La impresora de este teléfono vuelve a la configuración de '
            'fábrica (habrá que elegirla de nuevo).',
        confirmLabel: 'Restablecer',
        destructive: true,
        icon: LucideIcons.rotateCcw,
      );
      if (!ok) return;
      settings.resetDevice();
      showSettingsSaved('Impresora restablecida.');
    }

    Future<void> resetCompany() async {
      final ok = await ConfirmDialog.show(
        title: 'Restablecer ajustes de la empresa',
        message:
            'Los datos del negocio, los valores por defecto y las rutas '
            'vuelven a los de fábrica para todos los usuarios de la empresa. '
            'Clientes y préstamos no se tocan.',
        confirmLabel: 'Restablecer',
        destructive: true,
        icon: LucideIcons.rotateCcw,
      );
      if (!ok) return;
      settings.resetCompany();
      showSettingsSaved('Ajustes de la empresa restablecidos.');
    }

    Future<void> resetData() async {
      final ok = await ConfirmDialog.show(
        title: 'Restablecer datos de ejemplo',
        message:
            'Se borrarán los clientes, préstamos y pagos registrados y se '
            'cargarán de nuevo los datos de ejemplo.',
        confirmLabel: 'Restablecer',
        destructive: true,
        icon: LucideIcons.databaseBackup,
      );
      if (!ok) return;
      clients.resetSampleData();
      showSettingsSaved('Datos de ejemplo restablecidos.');
    }

    return SettingsPage(
      title: 'Datos y mantenimiento',
      children: [
        Obx(
          () => SettingsGroup(
            title: 'Resumen',
            children: [
              SettingsTile(
                icon: LucideIcons.users,
                title: 'Clientes',
                trailing: _Count(clients.clients.length),
              ),
              SettingsTile(
                icon: LucideIcons.layers,
                title: 'Préstamos activos',
                trailing: _Count(loans.loans.where((l) => !l.isPaidOff).length),
              ),
              SettingsTile(
                icon: LucideIcons.receiptText,
                title: 'Pagos registrados',
                trailing: _Count(loans.payments.length),
              ),
            ],
          ),
        ),
        SettingsGroup(
          title: 'Restablecer',
          children: [
            SettingsTile(
              icon: LucideIcons.printer,
              title: 'Restablecer impresora',
              subtitle: 'Solo en este teléfono',
              destructive: true,
              onTap: resetPrinter,
            ),
            if (CompanySettingsSync.canEdit)
              SettingsTile(
                icon: LucideIcons.rotateCcw,
                title: 'Restablecer ajustes de la empresa',
                subtitle: 'Negocio, préstamos por defecto y rutas',
                destructive: true,
                onTap: resetCompany,
              ),
            if (clients.isSample)
              SettingsTile(
                icon: LucideIcons.databaseBackup,
                title: 'Restablecer datos de ejemplo',
                subtitle: 'Mientras no hay base de datos conectada',
                destructive: true,
                onTap: resetData,
              ),
          ],
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.value);

  final int value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}
