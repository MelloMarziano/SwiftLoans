import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';

/// Caja de campo del formulario: ícono a la izquierda, etiqueta pequeña
/// arriba y el valor/entrada debajo. Muestra el error debajo de la caja.
class FieldBox extends StatelessWidget {
  const FieldBox({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.required = false,
    this.trailing,
    this.onTap,
    this.error,
    this.readOnly = false,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool required;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? error;

  /// Valores calculados: fondo suave para diferenciarlos de las entradas.
  final bool readOnly;

  /// Estilo del valor, para que entradas y textos se vean iguales.
  static TextStyle valueStyle(BuildContext context) => TextStyle(
    fontSize: context.sized(15, 17),
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.sized(14, 16));
    final iconBox = context.sized(34.0, 40.0);
    final hasError = error != null;

    final box = Ink(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF5FAFB) : AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: hasError ? AppColors.danger : AppColors.border,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.sized(10, 12),
            vertical: context.sized(9, 11),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // En cajas angostas (2 columnas en teléfono) el ícono se oculta
              // para que la etiqueta y el valor se lean completos.
              final showIcon = constraints.maxWidth >= 170;

              return Row(
                children: [
                  if (showIcon) ...[
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(iconBox * 0.3),
                      ),
                      child: Icon(
                        icon,
                        size: iconBox * 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: context.sized(10, 12)),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: label,
                            children: [
                              if (required)
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: AppColors.danger),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: context.sized(11.5, 13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        child,
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    trailing!,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(color: Colors.transparent, child: box),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
