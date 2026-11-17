import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../utils/date_period.dart';
import '../utils/responsive.dart';

/// Hoy · Ayer · Esta semana · Este mes · Rango (con calendario).
class PeriodChips extends StatelessWidget {
  const PeriodChips({
    super.key,
    required this.period,
    required this.customRange,
    required this.today,
  });

  final Rx<DatePeriod> period;
  final Rxn<DateTimeRange> customRange;
  final DateTime today;

  static final _short = DateFormat('dd/MM');

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 3),
      lastDate: DateTime(today.year, today.month, today.day),
      initialDateRange: customRange.value,
      helpText: 'Elige el rango',
      saveText: 'Aplicar',
    );
    if (picked == null) return;
    customRange.value = picked;
    period.value = DatePeriod.custom;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.sized(38.0, 42.0),
      child: Obx(() {
        final selected = period.value;
        final range = customRange.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: DatePeriod.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final p = DatePeriod.values[i];
            final isSelected = p == selected;
            final custom = p == DatePeriod.custom;
            final label = custom && range != null
                ? '${_short.format(range.start)} – ${_short.format(range.end)}'
                : p.label;
            return ChoiceChip(
              avatar: custom
                  ? Icon(
                      LucideIcons.calendarRange,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    )
                  : null,
              label: Text(label),
              selected: isSelected,
              onSelected: (_) =>
                  custom ? _pickRange(context) : period.value = p,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: context.sized(13, 14),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            );
          },
        );
      }),
    );
  }
}
