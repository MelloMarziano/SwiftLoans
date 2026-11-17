import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/session_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../routes/app_routes.dart';
import '../root_controller.dart';

/// Barra superior fija de las pantallas principales.
/// En móvil muestra el logo; en tablet/web el título de la sección,
/// porque el logo ya está en la barra lateral.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, this.title, this.alwaysShowLogo = false});

  /// Título en tablet/web; por defecto, el de la pestaña activa.
  final String? title;

  /// Muestra el logo también en tablet/web (pantallas sin barra lateral).
  final bool alwaysShowLogo;

  @override
  Widget build(BuildContext context) {
    final root = Get.find<RootController>();
    final session = Get.find<SessionService>();
    final compact = context.isCompact;
    final actionSize = context.sized(40, 44);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.background, Color(0xFFE2F4F7)],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: context.sized(60, 72),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.sized(14, 32)),
            child: Row(
              children: [
                Expanded(
                  child: compact || alwaysShowLogo
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: BrandWordmark(height: 34),
                        )
                      : Obx(
                          () => Text(
                            root.titleFor(title),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Obx(
                  () => _NotificationBell(
                    size: actionSize,
                    count: session.unreadNotifications.value,
                    onTap: () => Get.toNamed(Routes.notifications),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(
                  () => _UserAvatar(
                    size: actionSize,
                    initials: session.userInitials.value,
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.size,
    required this.count,
    required this.onTap,
  });

  final double size;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.3);

    return Semantics(
      button: true,
      label: 'Notificaciones, $count sin leer',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.surface,
            borderRadius: radius,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  LucideIcons.bell,
                  size: size * 0.48,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.size, required this.initials});

  final double size;
  final String initials;

  @override
  Widget build(BuildContext context) {
    // Tocar el avatar abre Ajustes.
    return Tooltip(
      message: 'Ajustes',
      child: Material(
        color: AppColors.avatar,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => Get.toNamed(Routes.settings),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
