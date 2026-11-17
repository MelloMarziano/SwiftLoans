import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../root_controller.dart';

/// Botón de navegación compartido por la barra inferior y la lateral.
class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    this.horizontal = false,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final icon = Icon(item.icon, size: 24, color: color);
    final label = Text(
      item.label,
      maxLines: 1,
      style: TextStyle(
        fontSize: horizontal ? 15 : 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: selected ? AppColors.primary : AppColors.textPrimary,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: horizontal ? 16 : 4,
              vertical: horizontal ? 14 : 10,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: horizontal
                ? Row(children: [icon, const SizedBox(width: 12), label])
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(height: 4),
                      FittedBox(fit: BoxFit.scaleDown, child: label),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
