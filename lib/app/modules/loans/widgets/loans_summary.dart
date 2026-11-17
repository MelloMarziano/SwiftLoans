import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/motion.dart';
import '../loans_controller.dart';

/// Totales de la cartera. Cada tarjeta lleva a su pestaña de la lista.
class LoansSummary extends GetView<LoansController> {
  const LoansSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.tab.value;
      final tiles = [
        _SummaryTile(
          icon: LucideIcons.wallet,
          label: 'Cartera activa',
          value: controller.portfolio,
          caption: '${controller.activeCount} préstamos',
          color: AppColors.primary,
          soft: AppColors.accentSoft,
          selected: tab == LoanTab.active,
          onTap: () => controller.changeTab(LoanTab.active),
        ),
        _SummaryTile(
          icon: LucideIcons.coins,
          label: 'Cobrar hoy',
          value: controller.dueTodayAmount,
          caption: controller.dueTodayCount == 1
              ? '1 cuota'
              : '${controller.dueTodayCount} cuotas',
          color: AppColors.success,
          soft: AppColors.successSoft,
          selected: tab == LoanTab.today,
          onTap: () => controller.changeTab(LoanTab.today),
        ),
        _SummaryTile(
          icon: LucideIcons.clockAlert,
          label: 'Vencidos',
          value: controller.overdueAmount,
          caption:
              '${controller.overdueCount} · mora '
              '${Formatters.compact(controller.lateFeeDue)}',
          color: AppColors.danger,
          soft: AppColors.dangerSoft,
          selected: tab == LoanTab.overdue,
          onTap: () => controller.changeTab(LoanTab.overdue),
        ),
        _SummaryTile(
          icon: LucideIcons.handCoins,
          label: 'Prestado',
          value: controller.disbursedAmount,
          caption: controller.disbursedCount == 1
              ? '1 este mes'
              : '${controller.disbursedCount} este mes',
          color: AppColors.primaryDark,
          soft: const Color(0xFFE6ECEE),
          selected: false,
          onTap: () {
            controller.changeTab(LoanTab.all);
            controller.sort.value = LoanSort.newest;
          },
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 4 : 2;
          const spacing = 10.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [for (final t in tiles) SizedBox(width: width, child: t)],
          );
        },
      );
    });
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.soft,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double value;
  final String caption;
  final Color color;
  final Color soft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label ${Formatters.compact(value)}, $caption',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.6) : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsets.all(context.sized(12, 16)),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: context.sized(12, 13),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedNumber(
                            value: value,
                            format: Formatters.compact,
                            style: TextStyle(
                              fontSize: context.sized(18, 22),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
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
