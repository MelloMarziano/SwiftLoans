import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../clients_controller.dart';
import 'client_filters_sheet.dart';

class ClientSearchBar extends GetView<ClientsController> {
  const ClientSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final height = context.sized(46.0, 52.0);
    final fontSize = context.sized(14.0, 15.0);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: Obx(
              () => TextField(
                controller: controller.searchController,
                onChanged: controller.search,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                  hintText: context.isCompact
                      ? 'Buscar cliente...'
                      : 'Buscar cliente, ID o cédula...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: fontSize,
                  ),
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  prefixIconColor: AppColors.textSecondary,
                  suffixIcon: controller.query.value.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: controller.clearSearch,
                          icon: const Icon(LucideIcons.x, size: 18),
                        ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: EdgeInsets.zero,
                  border: _border(AppColors.border),
                  enabledBorder: _border(AppColors.border),
                  focusedBorder: _border(AppColors.primary, 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: height,
          child: Obx(
            () => Badge(
              isLabelVisible: controller.hasActiveFilters,
              smallSize: 10,
              backgroundColor: AppColors.primary,
              child: OutlinedButton.icon(
                onPressed: () => ClientFiltersSheet.show(),
                icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
                label: const Text('Filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.sized(14, 20),
                  ),
                  textStyle: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: color, width: width),
      );
}
