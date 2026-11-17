import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/client.dart';

class ClientStatusChip extends StatelessWidget {
  const ClientStatusChip({super.key, required this.status});

  final ClientLoanStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (status) {
      ClientLoanStatus.toCollect => (
        LucideIcons.coins,
        AppColors.successSoft,
        AppColors.success,
      ),
      ClientLoanStatus.upToDate => (
        LucideIcons.circleCheck,
        AppColors.accentSoft,
        AppColors.primary,
      ),
      ClientLoanStatus.overdue => (
        LucideIcons.clockAlert,
        AppColors.dangerSoft,
        AppColors.danger,
      ),
      ClientLoanStatus.none => (
        LucideIcons.circleMinus,
        const Color(0xFFEFF3F4),
        AppColors.textSecondary,
      ),
    };

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
