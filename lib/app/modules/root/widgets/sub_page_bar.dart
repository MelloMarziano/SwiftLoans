import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';

/// Barra de las subpantallas (Nueva solicitud, Ficha del cliente...):
/// regreso + título, sin logo ni accesos de la barra principal.
class SubPageBar extends StatelessWidget {
  const SubPageBar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: context.sized(56, 64),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.sized(6, 20)),
            child: Row(
              children: [
                IconButton(
                  onPressed: Get.back,
                  tooltip: 'Regresar',
                  icon: const Icon(LucideIcons.arrowLeft, size: 22),
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.sized(17, 20),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
