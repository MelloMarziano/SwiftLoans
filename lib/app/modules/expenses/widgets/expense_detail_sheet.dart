import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/auth_backend.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../data/models/expense.dart';
import '../../../data/repositories/expense_repository.dart';
import 'expense_category_style.dart';

/// Detalle de un gasto. Dueño, administrador y ROOT lo pueden borrar.
class ExpenseDetailSheet extends StatelessWidget {
  const ExpenseDetailSheet({super.key, required this.expense});

  final Expense expense;

  static Future<void> show(Expense expense) => Get.bottomSheet(
    ExpenseDetailSheet(expense: expense),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );

  static final _date = DateFormat('dd/MM/yyyy h:mm a');

  Future<void> _delete() async {
    final ok = await ConfirmDialog.show(
      title: 'Borrar gasto',
      message:
          '¿Borrar "${expense.title}" de ${Formatters.currency2(expense.amount)}? '
          'Deja de contar en Movimientos y en el cuadre.',
      confirmLabel: 'Borrar',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    try {
      await Get.find<ExpenseRepository>().delete(expense);
      Get.back();
    } on AuthFailure catch (e) {
      Get.snackbar(
        'No se pudo borrar',
        e.message,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final rows = [
      ('Categoría', e.category.label),
      ('Fecha', _date.format(e.date)),
      ('Pagado con', e.method.label),
      ('Registrado por', e.byName.isEmpty ? '—' : e.byName),
      ('Número', e.id),
    ];

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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.dangerSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          e.category.icon,
                          color: AppColors.danger,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '−${Formatters.currency2(e.amount)}',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final (label, value) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            value,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  if (Get.find<ExpenseRepository>().canDelete) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      label: const Text('Borrar gasto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
