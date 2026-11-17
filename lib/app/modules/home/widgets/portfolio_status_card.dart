import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../root/root_controller.dart';
import '../home_controller.dart';

class PortfolioStatusCard extends GetView<HomeController> {
  const PortfolioStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Estado de la cartera',
                    style: TextStyle(
                      fontSize: context.sized(16, 18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${controller.loansCount.value} préstamos',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: context.sized(13, 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    Expanded(
                      flex: controller.activeLoans,
                      child: Container(color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: controller.overdueCount.value,
                      child: Container(color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Legend(
                    color: AppColors.primary,
                    label: 'Activos',
                    count: controller.activeLoans,
                    ratio: controller.activeRatio,
                  ),
                ),
                Expanded(
                  child: _Legend(
                    color: AppColors.accent,
                    label: 'Vencidos',
                    count: controller.overdueCount.value,
                    ratio: controller.overdueRatio,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ManageOverdueButton(
              count: controller.overdueCount.value,
              newThisPeriod: controller.overdueDelta.value,
              onTap: () => controller.goToTab(RootController.loans),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.count,
    required this.ratio,
  });

  final Color color;
  final String label;
  final int count;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 14, right: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 15),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: ' · ${Formatters.percent(ratio)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: context.sized(16, 18)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageOverdueButton extends StatelessWidget {
  const _ManageOverdueButton({
    required this.count,
    required this.newThisPeriod,
    required this.onTap,
  });

  final int count;
  final int newThisPeriod;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Material(
      color: AppColors.tile,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.triangleAlert,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestionar $count vencidos',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: context.sized(15, 17),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$newThisPeriod nuevos este mes',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
