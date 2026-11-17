import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../clients_controller.dart';

/// Hoja inferior con filtros por estado y orden de la lista.
class ClientFiltersSheet extends StatefulWidget {
  const ClientFiltersSheet({super.key});

  static Future<void> show() => Get.bottomSheet(
    const ClientFiltersSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );

  @override
  State<ClientFiltersSheet> createState() => _ClientFiltersSheetState();
}

class _ClientFiltersSheetState extends State<ClientFiltersSheet> {
  final controller = Get.find<ClientsController>();
  late var status = controller.statusFilter.value;
  late var sort = controller.sort.value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Estado'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in ClientStatusFilter.values)
                        _Choice(
                          label: s.label,
                          selected: status == s,
                          onTap: () => setState(() => status = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Ordenar por'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in ClientSort.values)
                        _Choice(
                          label: s.label,
                          selected: sort == s,
                          onTap: () => setState(() => sort = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            controller.resetFilters();
                            Get.back();
                          },
                          style: _buttonStyle(outlined: true),
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            controller.applyFilters(status, sort);
                            Get.back();
                          },
                          style: _buttonStyle(),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle({bool outlined = false}) {
    final base = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
          )
        : FilledButton.styleFrom(backgroundColor: AppColors.primary);
    return base.copyWith(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
