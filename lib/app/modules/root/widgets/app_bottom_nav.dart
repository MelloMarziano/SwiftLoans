import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../root_controller.dart';

/// Barra inferior flotante (móvil) con efecto vidrio: desenfoca el contenido
/// que pasa por detrás y un indicador se desliza a la pestaña activa.
class AppBottomNav extends GetView<RootController> {
  const AppBottomNav({super.key, this.activeTab});

  /// Pestaña resaltada en pantallas abiertas encima del menú.
  final int? activeTab;

  static const _height = 62.0;
  static const _padding = 5.0;
  static final _radius = BorderRadius.circular(28);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: DecoratedBox(
        // La sombra va fuera del recorte para que no la corte el ClipRRect.
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.14),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: _height,
              padding: const EdgeInsets.all(_padding),
              decoration: BoxDecoration(
                borderRadius: _radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.72),
                    Colors.white.withValues(alpha: 0.45),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  // Brillo superior, como el reflejo del vidrio.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: _radius,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.white.withValues(alpha: 0.45),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Obx(() => _items(controller.selectedTab(activeTab))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Cuánto más ancha es la pestaña activa que las demás. Así la gota
  /// envuelve etiquetas largas como "Movimientos" sin que se salgan.
  static const _selectedWeight = 1.4;
  static const _duration = Duration(milliseconds: 380);
  static const _curve = Curves.easeOutCubic;

  Widget _items(int selected) {
    const items = RootController.items;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasSelection = selected >= 0;
        final unit =
            constraints.maxWidth /
            (items.length - 1 + (hasSelection ? _selectedWeight : 1));
        double widthOf(int i) => i == selected ? unit * _selectedWeight : unit;
        final left = [
          for (var i = 0, x = 0.0; i < items.length; x += widthOf(i), i++) x,
        ];

        return Stack(
          children: [
            AnimatedPositioned(
              duration: _duration,
              curve: _curve,
              left: hasSelection ? left[selected] : 0,
              top: 0,
              bottom: 0,
              width: hasSelection ? widthOf(selected) : unit,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hasSelection ? 1 : 0,
                child: const _GlassIndicator(),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  AnimatedContainer(
                    duration: _duration,
                    curve: _curve,
                    width: widthOf(i),
                    child: _GlassNavItem(
                      item: items[i],
                      selected: selected == i,
                      onTap: () => controller.goToTab(i),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GlassIndicator extends StatelessWidget {
  const _GlassIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            AppColors.accentSoft.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : AppColors.textPrimary.withValues(alpha: 0.7);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        highlightShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(23),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 220),
                child: Icon(item.icon, size: 20, color: color),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: -0.1,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
