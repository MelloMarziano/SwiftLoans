import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../clients_controller.dart';

class ClientsHeader extends GetView<ClientsController> {
  const ClientsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En tablet/web el título ya está en la barra superior.
              if (compact)
                const Text(
                  'Clientes',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              Text(
                'Administra tu cartera de clientes',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: controller.openNewClient,
          icon: Icon(LucideIcons.plus, size: compact ? 18 : 20),
          label: const Text('Nuevo cliente'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: compact ? 10 : 14,
            ),
            textStyle: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
