import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';

enum TrendTone { positive, negative, onDark }

/// Pastilla con flecha y variación, p. ej. "↑ +5".
class TrendBadge extends StatelessWidget {
  const TrendBadge({
    super.key,
    required this.label,
    this.tone = TrendTone.positive,
    this.up = true,
  });

  final String label;
  final TrendTone tone;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      TrendTone.positive => (AppColors.successSoft, AppColors.success),
      TrendTone.negative => (AppColors.dangerSoft, AppColors.danger),
      TrendTone.onDark => (const Color(0xFF1C8A63), const Color(0xFFD9FBE8)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? LucideIcons.arrowUp : LucideIcons.arrowDown,
            size: context.sized(12, 14),
            color: fg,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: context.sized(11, 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
