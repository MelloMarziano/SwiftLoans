import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../loans_controller.dart';

class LoanStatusChip extends StatelessWidget {
  const LoanStatusChip({super.key, required this.status});

  final LoanStatus status;

  static (IconData, Color, Color) styleOf(LoanStatus status) =>
      switch (status) {
        LoanStatus.dueToday => (
          LucideIcons.coins,
          AppColors.successSoft,
          AppColors.success,
        ),
        LoanStatus.upToDate => (
          LucideIcons.circleCheck,
          AppColors.accentSoft,
          AppColors.primary,
        ),
        LoanStatus.overdue => (
          LucideIcons.clockAlert,
          AppColors.dangerSoft,
          AppColors.danger,
        ),
        LoanStatus.paidOff => (
          LucideIcons.badgeCheck,
          const Color(0xFFEFF3F4),
          AppColors.textSecondary,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = styleOf(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.sized(9, 12),
        vertical: context.sized(5, 7),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.sized(14, 16), color: fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: context.sized(12, 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
