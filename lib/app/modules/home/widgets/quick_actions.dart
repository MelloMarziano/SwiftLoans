import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../home_controller.dart';

class QuickActions extends GetView<HomeController> {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    const actions = HomeController.quickActions;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 600 ? 10.0 : 12.0;
        final tileWidth =
            (constraints.maxWidth - gap * (actions.length - 1)) /
            actions.length;
        // Casi cuadrados en móvil; en pantallas grandes no crecen de más.
        final tileHeight = (tileWidth * 0.9).clamp(74.0, 112.0);

        return Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                child: QuickActionButton(
                  action: actions[i],
                  height: tileHeight,
                  onTap: () => controller.openQuickAction(actions[i]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.action,
    required this.onTap,
    this.height = 110,
  });

  final QuickAction action;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final compact = height < 100;
    final radius = BorderRadius.circular(compact ? 18 : 22);

    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.tile, Color(0xFFF4FBFC)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            highlightColor: AppColors.accent.withValues(alpha: 0.18),
            splashColor: AppColors.accent.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    action.icon,
                    size: compact ? 24 : 32,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      action.label,
                      style: TextStyle(
                        fontSize: compact ? 13 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
