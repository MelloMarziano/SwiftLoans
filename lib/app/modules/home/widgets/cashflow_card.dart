import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../root/root_controller.dart';
import '../home_controller.dart';
import 'weekly_bar_chart.dart';

/// Cobros vs. desembolsos de la semana, con selección por día.
class CashflowCard extends GetView<HomeController> {
  const CashflowCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Obx(() {
        final selected = controller.selectedDay.value;
        // Se leen aquí (y no dentro del LayoutBuilder) para que el Obx los
        // registre y el gráfico se actualice al llegar cobros o préstamos.
        final collectionsShown = controller.collectionsShown;
        final disbursementsShown = controller.disbursementsShown;
        final flow = controller.weeklyFlow.toList();
        final subtitle = selected == null
            ? 'Esta semana · toca un día'
            : '${controller.weeklyFlow[selected].day} · toca de nuevo para ver la semana';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cobros vs. desembolsos',
                        style: TextStyle(
                          fontSize: context.sized(16, 18),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => controller.goToTab(RootController.movements),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver más',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(width: 4),
                      Icon(LucideIcons.chevronRight, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final collections = _FlowSummary(
                  icon: LucideIcons.arrowDown,
                  iconColor: AppColors.success,
                  iconBg: AppColors.successSoft,
                  label: 'Cobros',
                  amount: collectionsShown,
                );
                final disbursements = _FlowSummary(
                  icon: LucideIcons.arrowUp,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.accentSoft,
                  label: 'Desembolsos',
                  amount: disbursementsShown,
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    children: [
                      collections,
                      const SizedBox(height: 10),
                      disbursements,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: collections),
                    const SizedBox(width: 12),
                    Expanded(child: disbursements),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            WeeklyBarChart(
              data: flow,
              selected: selected,
              onSelect: controller.toggleDay,
            ),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppColors.primary, label: 'Cobros'),
                SizedBox(width: 24),
                _LegendDot(color: AppColors.accent, label: 'Desembolsos'),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _FlowSummary extends StatelessWidget {
  const _FlowSummary({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: context.sized(12, 14))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formatters.currency(amount),
                    style: TextStyle(
                      fontSize: context.sized(16, 18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
