import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/session_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../home_controller.dart';

/// Saludo y selector de periodo del dashboard.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Text(
                  'Hola, ${session.userName.value} 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.sized(21, 28),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Resumen de tu cartera',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _PeriodSelector(),
      ],
    );
  }
}

class _PeriodSelector extends GetView<HomeController> {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return PopupMenuButton<DashboardPeriod>(
      onSelected: controller.changePeriod,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      itemBuilder: (_) => [
        for (final p in DashboardPeriod.values)
          PopupMenuItem(value: p, child: Text(p.label)),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendar, size: compact ? 16 : 20),
            SizedBox(width: compact ? 6 : 8),
            Obx(
              () => Text(
                controller.period.value.label,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: compact ? 14 : 18),
          ],
        ),
      ),
    );
  }
}
