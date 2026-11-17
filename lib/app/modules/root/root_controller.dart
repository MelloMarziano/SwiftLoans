import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../routes/app_routes.dart';

class NavItem {
  const NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Controla la pestaña activa del menú principal.
class RootController extends GetxController {
  static const items = <NavItem>[
    NavItem(label: 'Inicio', icon: LucideIcons.house),
    NavItem(label: 'Clientes', icon: LucideIcons.users),
    NavItem(label: 'Préstamos', icon: LucideIcons.layers),
    NavItem(label: 'Movimientos', icon: LucideIcons.arrowLeftRight),
    NavItem(label: 'Reportes', icon: LucideIcons.chartNoAxesColumn),
  ];

  static const home = 0;
  static const clients = 1;
  static const loans = 2;
  static const movements = 3;
  static const reports = 4;

  /// Para pantallas que no pertenecen a ninguna pestaña (p. ej. Ajustes).
  static const none = -1;

  final currentIndex = home.obs;

  void changeTab(int index) => currentIndex.value = index;

  // Ambos leen currentIndex siempre, aunque haya override, para que los Obx
  // que los usan tengan un observable registrado.
  int selectedTab(int? override) {
    final current = currentIndex.value;
    return override ?? current;
  }

  String titleFor(String? override) {
    final current = items[currentIndex.value].label;
    return override ?? current;
  }

  /// Desde una pantalla abierta encima del menú (p. ej. Nueva solicitud),
  /// vuelve al menú principal y abre la pestaña indicada.
  void goToTab(int index) {
    if (Get.currentRoute != Routes.root) {
      Get.until((route) => route.settings.name == Routes.root);
    }
    changeTab(index);
  }
}
