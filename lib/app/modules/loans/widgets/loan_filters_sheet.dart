import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/filter_sheet.dart';
import '../../../data/models/loan_terms.dart';
import '../loans_controller.dart';

/// Filtros por frecuencia y ruta, y el orden de la lista.
class LoanFiltersSheet extends StatefulWidget {
  const LoanFiltersSheet({super.key});

  static Future<void> show() => FilterSheet.show(const LoanFiltersSheet());

  @override
  State<LoanFiltersSheet> createState() => _LoanFiltersSheetState();
}

class _LoanFiltersSheetState extends State<LoanFiltersSheet> {
  final controller = Get.find<LoansController>();
  late final frequencies = {...controller.frequencies};
  late final routes = {...controller.routes};
  late var sort = controller.sort.value;

  void _toggle<T>(Set<T> set, T value) =>
      setState(() => set.contains(value) ? set.remove(value) : set.add(value));

  @override
  Widget build(BuildContext context) {
    final availableRoutes = controller.availableRoutes;

    return FilterSheet(
      onClear: controller.resetFilters,
      onApply: () => controller.applyFilters(
        frequencies: frequencies,
        routes: routes,
        sort: sort,
      ),
      sections: [
        FilterSection(
          label: 'Frecuencia',
          choices: [
            for (final f in PaymentFrequency.values)
              FilterChoice(
                label: f.label,
                selected: frequencies.contains(f),
                onTap: () => _toggle(frequencies, f),
              ),
          ],
        ),
        if (availableRoutes.length > 1)
          FilterSection(
            label: 'Ruta',
            choices: [
              for (final r in availableRoutes)
                FilterChoice(
                  label: r,
                  selected: routes.contains(r),
                  onTap: () => _toggle(routes, r),
                ),
            ],
          ),
        FilterSection(
          label: 'Ordenar por',
          choices: [
            for (final s in LoanSort.values)
              FilterChoice(
                label: s.label,
                selected: sort == s,
                onTap: () => setState(() => sort = s),
              ),
          ],
        ),
      ],
    );
  }
}
