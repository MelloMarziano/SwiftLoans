import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/demo_mode.dart';
import 'app_bottom_nav.dart';
import 'app_side_nav.dart';
import 'app_top_bar.dart';
import 'demo_banner.dart';
import 'root_viewing_banner.dart';
import 'sub_page_bar.dart';

/// Estructura común: barra superior fija + navegación (inferior en móvil,
/// lateral en tablet/web). La usan el menú principal y las subpantallas que
/// se abren encima de él, para no perder la navegación.
///
/// Las pantallas principales llevan la barra con logo; las subpantallas
/// ([showBack]) llevan una barra simple con regreso y título.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    this.title,
    this.showBack = false,
    this.activeTab,
    this.actions = const [],
  });

  final Widget body;
  final String? title;
  final bool showBack;
  final int? activeTab;

  /// Acciones a la derecha de la barra de subpantalla.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    // El ROOT ve la app con los datos de la empresa elegida; el aviso le
    // recuerda cuál es y le deja cambiarla.
    final isRoot = Get.find<AuthService>().user.value?.isRoot ?? false;
    final useSideNav = breakpoints.largerThan(MOBILE);

    final content = Column(
      children: [
        if (showBack)
          SubPageBar(title: title ?? '', actions: actions)
        else
          AppTopBar(title: title),
        if (isRoot) const RootViewingBanner(),
        if (DemoMode.active) const DemoBanner(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: body,
          ),
        ),
      ],
    );

    return Scaffold(
      extendBody: true,
      body: useSideNav
          ? Row(
              children: [
                AppSideNav(
                  extended: breakpoints.isDesktop,
                  activeTab: activeTab,
                ),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: !useSideNav
          ? AppBottomNav(activeTab: activeTab)
          : null,
    );
  }
}
