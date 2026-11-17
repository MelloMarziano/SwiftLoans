import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/empty_state.dart';
import 'loan_detail_view.dart';
import 'loans_controller.dart';
import 'widgets/loan_card.dart';
import 'widgets/loan_filters_sheet.dart';
import 'widgets/loans_summary.dart';

/// Préstamos: cómo va cada uno y qué toca cobrar. En pantallas anchas la
/// lista y el detalle se ven lado a lado.
class LoansView extends GetView<LoansController> {
  const LoansView({super.key});

  static const _sideBySideWidth = 1100.0;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          compact ? 14.0 : 32.0,
          (constraints.maxWidth - 1400) / 2,
        );
        final gap = context.sized(14.0, 20.0);

        if (constraints.maxWidth >= _sideBySideWidth) {
          return Padding(
            padding: EdgeInsets.fromLTRB(side, gap, side, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                SizedBox(height: gap),
                const LoansSummary().entrance(1),
                SizedBox(height: gap),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 440,
                        child: Column(
                          children: [
                            const _SearchBar(),
                            const SizedBox(height: 12),
                            const _Tabs(),
                            const SizedBox(height: 12),
                            Expanded(child: _SideList()),
                          ],
                        ),
                      ),
                      SizedBox(width: gap),
                      const Expanded(child: _SelectedDetail()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final columns = constraints.maxWidth >= 760 ? 2 : 1;

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, gap, side, 0),
              sliver: SliverList.list(
                children: [
                  const _Header(),
                  SizedBox(height: gap),
                  const LoansSummary().entrance(1),
                  SizedBox(height: gap),
                  const _SearchBar(),
                  const SizedBox(height: 12),
                  const _Tabs(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 0, side, compact ? 120 : 32),
              sliver: Obx(() {
                final rows = controller.visible;
                if (rows.isEmpty) {
                  return const SliverToBoxAdapter(child: _Empty());
                }
                Widget card(int i) => LoanCard(
                  key: ValueKey(rows[i].loan.id),
                  row: rows[i],
                  onTap: () => controller.open(rows[i], sideBySide: false),
                  onCollect: () => controller.collect(rows[i]),
                );

                if (columns == 1) {
                  return SliverList.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => card(i).entrance(i),
                  );
                }
                return SliverGrid.builder(
                  itemCount: rows.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 150,
                  ),
                  itemBuilder: (_, i) => card(i).entrance(i),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends GetView<LoansController> {
  const _Header();

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
                  'Préstamos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              Text(
                'Cómo va cada préstamo y qué toca cobrar',
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
          onPressed: controller.newLoan,
          icon: Icon(LucideIcons.plus, size: compact ? 18 : 20),
          label: const Text('Nuevo préstamo'),
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

class _SearchBar extends GetView<LoansController> {
  const _SearchBar();

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: color, width: width),
      );

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
                  hintText: 'Buscar cliente o préstamo...',
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
                onPressed: LoanFiltersSheet.show,
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
}

/// Activos · Hoy · Vencidos · Saldados · Todos, con su cantidad.
class _Tabs extends GetView<LoansController> {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.sized(38.0, 42.0),
      child: Obx(() {
        final selected = controller.tab.value;
        controller.rows.length; // refresca los contadores
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: LoanTab.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final tab = LoanTab.values[i];
            final isSelected = tab == selected;
            return ChoiceChip(
              label: Text('${tab.label} (${controller.countFor(tab)})'),
              selected: isSelected,
              onSelected: (_) => controller.changeTab(tab),
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

class _SideList extends GetView<LoansController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.visible;
      final selected = controller.selectedId.value;
      if (rows.isEmpty) {
        return const SingleChildScrollView(child: _Empty());
      }
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => LoanCard(
          key: ValueKey(rows[i].loan.id),
          row: rows[i],
          selected: rows[i].loan.id == selected || (selected == null && i == 0),
          onTap: () => controller.open(rows[i], sideBySide: true),
          onCollect: () => controller.collect(rows[i]),
        ).entrance(i),
      );
    });
  }
}

/// Detalle del préstamo elegido (o del primero de la lista).
class _SelectedDetail extends GetView<LoansController> {
  const _SelectedDetail();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = controller.selectedId.value;
      final row =
          (id == null ? null : controller.rowById(id)) ??
          controller.visible.firstOrNull;
      if (row == null) {
        return const EmptyState(
          icon: LucideIcons.layers,
          title: 'Sin préstamo seleccionado',
          message: 'Elige un préstamo de la lista para ver su detalle.',
        );
      }
      return SingleChildScrollView(
        key: ValueKey(row.loan.id),
        padding: const EdgeInsets.only(bottom: 32),
        child: LoanDetailPanel(loanId: row.loan.id).entrance(),
      );
    });
  }
}

class _Empty extends GetView<LoansController> {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final noLoans = controller.rows.isEmpty;
    return EmptyState(
      icon: noLoans ? LucideIcons.layers : LucideIcons.searchX,
      title: noLoans ? 'Aún no hay préstamos' : 'Sin resultados',
      message: noLoans
          ? 'Crea el primero con "Nuevo préstamo".'
          : 'Prueba con otro nombre, otra pestaña o cambia los filtros.',
    );
  }
}
