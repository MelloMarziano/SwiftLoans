import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../clients_controller.dart';

/// Totales de clientes. Cada tarjeta también filtra la lista por estado.
class ClientsSummary extends GetView<ClientsController> {
  const ClientsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = context.sized(10, 12);

    return Obx(() {
      final selected = controller.statusFilter.value;

      return Row(
        children: [
          Expanded(
            child: _SummaryTile(
              icon: LucideIcons.users,
              value: controller.totalCount,
              label: 'Clientes',
              tone: _Tone.neutral,
              selected: selected == ClientStatusFilter.all,
              onTap: () => controller.applyFilters(
                ClientStatusFilter.all,
                controller.sort.value,
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _SummaryTile(
              icon: LucideIcons.userPlus,
              value: controller.activeCount,
              label: 'Activos',
              tone: _Tone.positive,
              selected: selected == ClientStatusFilter.active,
              onTap: () => controller.applyFilters(
                ClientStatusFilter.active,
                controller.sort.value,
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _SummaryTile(
              icon: LucideIcons.userX,
              value: controller.inactiveCount,
              label: 'Inactivos',
              tone: _Tone.muted,
              selected: selected == ClientStatusFilter.inactive,
              onTap: () => controller.applyFilters(
                ClientStatusFilter.inactive,
                controller.sort.value,
              ),
            ),
          ),
        ],
      );
    });
  }
}

enum _Tone { neutral, positive, muted }

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final _Tone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, iconBg, iconColor, labelColor) = switch (tone) {
      _Tone.neutral => (
        AppColors.surface,
        AppColors.accentSoft,
        AppColors.primary,
        AppColors.textSecondary,
      ),
      _Tone.positive => (
        const Color(0xFFEAF8F0),
        AppColors.successSoft,
        AppColors.success,
        AppColors.success,
      ),
      _Tone.muted => (
        const Color(0xFFF3F6F7),
        const Color(0xFFE6ECEE),
        AppColors.textSecondary,
        AppColors.textSecondary,
      ),
    };
    final radius = BorderRadius.circular(context.sized(18, 20));

    return Semantics(
      button: true,
      selected: selected,
      label: '$value $label',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? iconColor.withValues(alpha: 0.6)
                  : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 130;
                final iconSize = context.sized(38, 46);
                final iconBox = Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(iconSize * 0.32),
                  ),
                  child: Icon(icon, size: iconSize * 0.5, color: iconColor),
                );
                final texts = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: context.sized(20, 24),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: context.sized(12, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );

                return Padding(
                  padding: EdgeInsets.all(context.sized(12, 16)),
                  child: stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [iconBox, const SizedBox(height: 8), texts],
                        )
                      : Row(
                          children: [
                            iconBox,
                            const SizedBox(width: 12),
                            Expanded(child: texts),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
