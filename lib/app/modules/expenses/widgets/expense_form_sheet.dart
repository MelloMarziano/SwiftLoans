import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/auth_backend.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/filter_sheet.dart';
import '../../../core/widgets/form/form_fields.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/loan.dart';
import '../../../data/repositories/expense_repository.dart';

/// Hoja para registrar un gasto: monto, categoría, método y nota.
class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({super.key});

  static Future<void> show() => Get.bottomSheet(
    const ExpenseFormSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  var _category = ExpenseCategory.fuel;
  var _method = PaymentMethod.cash;
  var _submitted = false;
  var _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  double get _value => MoneyInputFormatter.parse(_amount.text);

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_value <= 0) return;
    setState(() => _saving = true);
    try {
      final expense = await Get.find<ExpenseRepository>().add(
        amount: _value,
        category: _category,
        method: _method,
        description: _description.text,
      );
      Get.back();
      Get.snackbar(
        'Gasto registrado',
        '${expense.title} · ${Formatters.currency2(expense.amount)}',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } on AuthFailure catch (e) {
      Get.snackbar(
        'No se pudo guardar',
        e.message,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + insets),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'Registrar gasto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextFieldBox.money(
                    icon: LucideIcons.banknote,
                    label: 'Monto',
                    controller: _amount,
                    required: true,
                    error: _submitted && _value <= 0
                        ? 'Ingresa el monto'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilterSection(
                    label: 'Categoría',
                    choices: [
                      for (final c in ExpenseCategory.values)
                        FilterChoice(
                          label: c.label,
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilterSection(
                    label: 'Pagado con',
                    choices: [
                      for (final m in PaymentMethod.values)
                        FilterChoice(
                          label: m.label,
                          selected: _method == m,
                          onTap: () => setState(() => _method = m),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFieldBox(
                    icon: LucideIcons.stickyNote,
                    label: 'Descripción (opcional)',
                    hint: 'Ej. gasolina del motor',
                    controller: _description,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(LucideIcons.check, size: 20),
                    label: const Text('Guardar gasto'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
