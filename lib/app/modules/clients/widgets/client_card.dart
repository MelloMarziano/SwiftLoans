import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/client.dart';
import 'client_status_chip.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.client,
    required this.onTap,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Client client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.sized(18, 20));
    final avatarSize = context.sized(44, 52);
    final inactive = !client.isActive;
    final compact = context.isCompact;
    final meta = Text(
      [
        'ID: ${client.id}',
        client.document ?? 'N/A',
        if (inactive) 'Inactivo',
      ].join('  |  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: context.sized(12, 14),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.sized(12, 16),
              vertical: context.sized(12, 14),
            ),
            child: Row(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: inactive
                        ? const Color(0xFFEFF3F4)
                        : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(avatarSize * 0.32),
                  ),
                  child: Icon(
                    LucideIcons.users,
                    size: avatarSize * 0.46,
                    color: inactive
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                ),
                SizedBox(width: context.sized(12, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.sized(15, 16),
                          fontWeight: FontWeight.w800,
                          color: inactive
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 2),
                      // En móvil el chip baja junto al ID para que el nombre
                      // tenga todo el ancho.
                      if (compact)
                        Row(
                          children: [
                            Expanded(child: meta),
                            const SizedBox(width: 8),
                            ClientStatusChip(status: client.loanStatus),
                          ],
                        )
                      else
                        meta,
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  ClientStatusChip(status: client.loanStatus),
                ],
                _ClientMenu(
                  client: client,
                  onEdit: onEdit,
                  onToggleActive: onToggleActive,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ClientAction { edit, toggleActive, delete }

/// Menú ⋮ con las acciones del cliente.
class _ClientMenu extends StatelessWidget {
  const _ClientMenu({
    required this.client,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    PopupMenuItem<_ClientAction> item(
      _ClientAction value,
      IconData icon,
      String label, {
      Color color = AppColors.textPrimary,
    }) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return PopupMenuButton<_ClientAction>(
      tooltip: 'Acciones',
      icon: const Icon(
        LucideIcons.ellipsisVertical,
        size: 20,
        color: AppColors.primary,
      ),
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      elevation: 6,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (action) => switch (action) {
        _ClientAction.edit => onEdit(),
        _ClientAction.toggleActive => onToggleActive(),
        _ClientAction.delete => onDelete(),
      },
      itemBuilder: (_) => [
        item(_ClientAction.edit, LucideIcons.pencil, 'Editar'),
        item(
          _ClientAction.toggleActive,
          client.isActive ? LucideIcons.userX : LucideIcons.userCheck,
          client.isActive ? 'Inactivar' : 'Activar',
        ),
        item(
          _ClientAction.delete,
          LucideIcons.trash2,
          'Eliminar',
          color: AppColors.danger,
        ),
      ],
    );
  }
}
