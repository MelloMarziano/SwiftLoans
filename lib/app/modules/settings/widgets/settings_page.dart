import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../root/root_controller.dart';
import '../../root/widgets/app_shell.dart';

/// Estructura común de las pantallas de Ajustes: barra de subpantalla,
/// contenido centrado de ancho limitado y, opcionalmente, botón Guardar.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.children,
    this.onSave,
    this.saveLabel = 'Guardar cambios',
    this.readOnly = false,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onSave;
  final String saveLabel;

  /// Muestra los valores sin dejar cambiarlos (p. ej. ajustes de la empresa
  /// para un cobrador).
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final gap = context.sized(16.0, 22.0);

    return AppShell(
      title: title,
      showBack: true,
      activeTab: RootController.none,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            context.sized(14, 32),
            context.sized(16, 24),
            context.sized(14, 32),
            context.isCompact ? 120 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (readOnly) ...[
                    const _ReadOnlyNotice(),
                    SizedBox(height: gap),
                  ],
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) SizedBox(height: gap),
                    if (readOnly)
                      IgnorePointer(
                        child: Opacity(opacity: 0.75, child: children[i]),
                      )
                    else
                      children[i],
                  ],
                  if (onSave != null && !readOnly) ...[
                    SizedBox(height: gap),
                    FilledButton.icon(
                      onPressed: onSave,
                      icon: const Icon(LucideIcons.save, size: 20),
                      label: Text(saveLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: Size.fromHeight(context.sized(50, 54)),
                        shape: const StadiumBorder(),
                        textStyle: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: context.sized(15, 16),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensaje de confirmación estándar de Ajustes.
void showSettingsSaved([String message = 'Los cambios se guardaron.']) {
  Get.snackbar(
    'Ajustes',
    message,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(16),
  );
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.lock, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estos ajustes son de la empresa. Solo el dueño o el '
              'administrador pueden cambiarlos.',
              style: TextStyle(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}
