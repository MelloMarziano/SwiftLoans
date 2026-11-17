import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/company_settings_sync.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../../data/repositories/client_repository.dart';
import '../widgets/settings_page.dart';

/// Agregar, renombrar y eliminar rutas de cobro / oficinas.
class RoutesSettingsView extends StatelessWidget {
  const RoutesSettingsView({super.key});

  SettingsService get _settings => Get.find<SettingsService>();
  ClientRepository get _clients => Get.find<ClientRepository>();

  String? _validate(String value, {String? current}) {
    final exists = _settings.routes.any(
      (r) => r.toUpperCase() == value.toUpperCase() && r != current,
    );
    return exists ? 'Ya existe una ruta con ese nombre' : null;
  }

  Future<void> _add() async {
    final name = await TextInputDialog.show(
      title: 'Nueva ruta',
      label: 'Nombre de la ruta u oficina',
      confirmLabel: 'Agregar',
      validator: _validate,
    );
    if (name == null) return;
    _settings.routes.add(name.toUpperCase());
  }

  Future<void> _rename(String route) async {
    final name = await TextInputDialog.show(
      title: 'Renombrar ruta',
      label: 'Nombre',
      initialValue: route,
      validator: (v) => _validate(v, current: route),
    );
    if (name == null || name.toUpperCase() == route) return;
    final upper = name.toUpperCase();
    _settings.routes[_settings.routes.indexOf(route)] = upper;
    await _clients.renameRoute(route, upper);
  }

  Future<void> _delete(String route) async {
    final inUse = _clients.countInRoute(route);
    if (inUse > 0 || _settings.routes.length == 1) {
      await ConfirmDialog.show(
        title: 'No se puede eliminar',
        message: inUse > 0
            ? '$route tiene $inUse ${inUse == 1 ? 'cliente' : 'clientes'}. '
                  'Muévelos a otra ruta primero.'
            : 'Debe quedar al menos una ruta.',
        confirmLabel: 'Entendido',
        showCancel: false,
        icon: LucideIcons.info,
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      title: 'Eliminar ruta',
      message: '¿Eliminar $route?',
      confirmLabel: 'Eliminar',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (confirmed) _settings.routes.remove(route);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      readOnly: !CompanySettingsSync.canEdit,
      title: 'Rutas y oficinas',
      children: [
        Obx(
          () => SettingsGroup(
            title: 'Rutas',
            children: [
              for (final route in _settings.routes)
                SettingsTile(
                  icon: LucideIcons.route,
                  title: route,
                  subtitle: _clientsLabel(_clients.countInRoute(route)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Renombrar',
                        onPressed: () => _rename(route),
                        icon: const Icon(LucideIcons.pencil, size: 18),
                        color: AppColors.primary,
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () => _delete(route),
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _add,
          icon: const Icon(LucideIcons.plus, size: 20),
          label: const Text('Agregar ruta'),
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

  static String _clientsLabel(int count) => switch (count) {
    0 => 'Sin clientes',
    1 => '1 cliente',
    _ => '$count clientes',
  };
}
