import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tarjeta blanca con borde suave usada en las secciones del dashboard.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding});

  final Widget child;

  /// Por defecto 16 en móvil y 20 en pantallas grandes.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ??
          EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
