import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/period_chips.dart';
import '../../data/models/expense.dart';
import '../root/root_controller.dart';
import '../root/widgets/app_shell.dart';
import 'expenses_controller.dart';
import 'widgets/expense_category_style.dart';

/// Gastos del negocio: total del periodo, por categoría y la lista.
class ExpensesView extends GetView<ExpensesController> {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Gastos',
      showBack: true,
      activeTab: RootController.none,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = context.isCompact;
          final side = math.max(
            compact ? 14.0 : 32.0,
            (constraints.maxWidth - 900) / 2,
          );
          final gap = context.sized(14.0, 20.0);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, gap, side, 0),
                sliver: SliverList.list(
                  children: [
                    FilledButton.icon(
                      onPressed: controller.addExpense,
                      icon: const Icon(LucideIcons.plus, size: 20),
                      label: const Text('Registrar gasto'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: Size.fromHeight(context.sized(50, 54)),
                        shape: const StadiumBorder(),
                        textStyle: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: context.sized(15, 16),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(height: gap),
                    PeriodChips(
                      period: controller.period,
                      customRange: controller.customRange,
                      today: controller.today,
                    ),
                    SizedBox(height: gap),
                    const _Totals().entrance(1),
                    SizedBox(height: gap),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, 0, side, compact ? 120 : 32),
                sliver: Obx(() {
                  final list = controller.visible;
                  if (list.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(
                        icon: LucideIcons.receipt,
                        title: 'Sin gastos',
                        message: 'No hay gastos registrados en este periodo.',
                      ),
                    );
                  }
                  return SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < list.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                indent: 64,
                                color: AppColors.border,
                              ),
                            ExpenseTile(
                              key: ValueKey(list[i].id),
                              expense: list[i],
                              showPerson: !controller.onlyMine,
                              onTap: () => controller.open(list[i]),
                            ).entrance(i),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Total del periodo y reparto por categoría (toca para filtrar).
class _Totals extends GetView<ExpensesController> {
  const _Totals();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.total;
      final parts = controller.byCategory;
      final selected = controller.categories;

      return Container(
        padding: EdgeInsets.all(context.sized(14, 18)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              controller.onlyMine ? 'Tus gastos' : 'Total gastado',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            AnimatedNumber(
              value: total,
              format: Formatters.currency2,
              style: TextStyle(
                color: AppColors.danger,
                fontSize: context.sized(24, 28),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              controller.visible.length == 1
                  ? '1 gasto'
                  : '${controller.visible.length} gastos',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (parts.isNotEmpty || selected.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final (category, amount) in parts)
                _CategoryBar(
                  category: category,
                  amount: amount,
                  ratio: total == 0 ? 0 : amount / total,
                  selected: selected.contains(category),
                  onTap: () => controller.toggleCategory(category),
                ),
              if (selected.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: selected.clear,
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('Ver todas las categorías'),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.ratio,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final double amount;
  final double ratio;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(category.icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            SizedBox(
              width: context.sized(110, 150),
              child: Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: AnimatedBar(
                value: ratio,
                background: const Color(0xFFF3F6F7),
                color: selected
                    ? AppColors.danger
                    : AppColors.danger.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              Formatters.currency(amount),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.showPerson,
    required this.onTap,
  });

  final Expense expense;
  final bool showPerson;
  final VoidCallback onTap;

  static final _when = DateFormat('dd/MM · h:mm a');

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final how = [
      e.category.label,
      e.method.label,
      if (showPerson && e.byName.isNotEmpty) e.byName,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.sized(12, 16),
          vertical: context.sized(10, 12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(e.category.icon, size: 19, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.sized(14.5, 15.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  for (final line in [_when.format(e.date), how])
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: context.sized(12, 13),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '−${Formatters.currency2(e.amount)}',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: context.sized(14.5, 15.5),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
