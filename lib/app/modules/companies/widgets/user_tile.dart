import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';

/// Fila de usuario con rol, estado y (opcional) interruptor para activarlo.
class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, this.onToggle});

  final AppUser user;

  /// null = no se puede cambiar su estado (p. ej. el dueño o uno mismo).
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (user.role) {
      UserRole.owner => AppColors.primaryDark,
      UserRole.admin => AppColors.primary,
      _ => AppColors.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: user.active
                ? AppColors.avatar
                : const Color(0xFFE6ECEE),
            child: Text(
              user.initials,
              style: TextStyle(
                color: user.active ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: user.active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  [
                    '@${user.username}',
                    if (!user.active) 'Inactivo',
                    if (user.mustChangePassword) 'Clave temporal',
                  ].join(' · '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.label,
              style: TextStyle(
                color: roleColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onToggle != null)
            Switch(
              value: user.active,
              activeThumbColor: AppColors.primary,
              onChanged: (_) => onToggle!(),
            ),
        ],
      ),
    );
  }
}
