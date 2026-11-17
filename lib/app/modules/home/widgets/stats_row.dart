import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/trend_badge.dart';
import '../../root/root_controller.dart';
import '../home_controller.dart';

/// Indicadores de clientes, préstamos y vencidos.
class StatsRow extends GetView<HomeController> {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = MediaQuery.sizeOf(context).width < 600 ? 10.0 : 12.0;

    return Obx(
      () => Row(
        children: [
          Expanded(
            child: StatTile(
              icon: LucideIcons.users,
              label: 'Clientes',
              value: controller.clientsCount.value,
              trend: '+${controller.clientsDelta.value}',
              onTap: () => controller.goToTab(RootController.clients),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: StatTile(
              icon: LucideIcons.layers,
              label: 'Préstamos',
              value: controller.loansCount.value,
              trend: '+${controller.loansDelta.value}',
              onTap: () => controller.goToTab(RootController.loans),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: StatTile(
              icon: LucideIcons.calendar,
              label: 'Vencidos',
              value: controller.overdueCount.value,
              trend: '+${controller.overdueDelta.value}',
              // Más vencidos es una mala noticia: se marca en rojo.
              tone: TrendTone.negative,
              onTap: () => controller.goToTab(RootController.loans),
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    this.tone = TrendTone.positive,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final String trend;
  final TrendTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // En pantallas angostas el ícono va arriba para que el número respire.
              final compact = constraints.maxWidth < 150;
              final iconBox = Icon(
                icon,
                size: context.sized(22, 26),
                color: AppColors.primaryDark,
              );
              final texts = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.sized(12, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          '$value',
                          style: TextStyle(
                            fontSize: context.sized(20, 24),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TrendBadge(label: trend, tone: tone),
                      ],
                    ),
                  ),
                ],
              );

              return Padding(
                padding: EdgeInsets.all(compact ? 12 : 14),
                child: compact
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
    );
  }
}
