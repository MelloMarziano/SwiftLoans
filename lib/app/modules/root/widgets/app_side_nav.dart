import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../routes/app_routes.dart';
import '../root_controller.dart';
import 'nav_button.dart';

/// Barra lateral (tablet y web). En escritorio se muestra extendida con etiquetas.
class AppSideNav extends GetView<RootController> {
  const AppSideNav({super.key, this.extended = false, this.activeTab});

  final bool extended;

  /// Pestaña resaltada en pantallas abiertas encima del menú.
  final int? activeTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: extended ? 240 : 104,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Column(
            crossAxisAlignment: extended
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: extended ? 8 : 0, bottom: 28),
                child: extended
                    ? const BrandWordmark(height: 48)
                    : const BrandLogo(size: 52),
              ),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < RootController.items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: NavButton(
                          item: RootController.items[i],
                          horizontal: extended,
                          selected: controller.selectedTab(activeTab) == i,
                          onTap: () => controller.goToTab(i),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              NavButton(
                item: const NavItem(
                  label: 'Ajustes',
                  icon: LucideIcons.settings,
                ),
                horizontal: extended,
                selected: Get.currentRoute.startsWith(Routes.settings),
                onTap: () => Get.toNamed(Routes.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
