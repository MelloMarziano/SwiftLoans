import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Hoja inferior de filtros: título, secciones con chips y los botones
/// Limpiar / Aplicar.
class FilterSheet extends StatelessWidget {
  const FilterSheet({
    super.key,
    required this.sections,
    required this.onClear,
    required this.onApply,
  });

  final List<FilterSection> sections;
  final VoidCallback onClear;
  final VoidCallback onApply;

  static Future<void> show(Widget sheet) => Get.bottomSheet(
    sheet,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
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
                  for (final section in sections) ...[
                    const SizedBox(height: 18),
                    section,
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            onClear();
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
                            onApply();
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

  static ButtonStyle _buttonStyle({bool outlined = false}) {
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

/// Grupo de opciones con su etiqueta.
class FilterSection extends StatelessWidget {
  const FilterSection({super.key, required this.label, required this.choices});

  final String label;
  final List<FilterChoice> choices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: choices),
      ],
    );
  }
}

class FilterChoice extends StatelessWidget {
  const FilterChoice({
    super.key,
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
