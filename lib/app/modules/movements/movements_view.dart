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
import '../../core/widgets/filter_sheet.dart';
import '../../core/widgets/period_chips.dart';
import '../../data/models/loan.dart';
import '../expenses/widgets/expense_category_style.dart';
import '../../routes/app_routes.dart';
import '../documents/document_actions.dart';
import '../documents/documents.dart';
import 'movements_controller.dart';

const _outColor = Color(0xFFB7791F);
const _outSoft = Color(0xFFFBF0DC);

final _time = DateFormat('h:mm a');

/// Movimientos: qué dinero entró (cobros) y salió (préstamos), cuándo y
/// quién lo movió.
class MovementsView extends GetView<MovementsController> {
  const MovementsView({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          compact ? 14.0 : 32.0,
          (constraints.maxWidth - 1000) / 2,
        );
        final gap = context.sized(14.0, 20.0);

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, gap, side, 0),
              sliver: SliverList.list(
                children: [
                  const _Header(),
                  SizedBox(height: gap),
                  PeriodChips(
                    period: controller.period,
                    customRange: controller.customRange,
                    today: controller.today,
                  ),
                  SizedBox(height: gap),
                  const _Summary().entrance(1),
                  SizedBox(height: gap),
                  const _SearchBar(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 0, side, compact ? 120 : 32),
              sliver: Obx(() {
                final days = controller.days;
                if (days.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: LucideIcons.arrowLeftRight,
                      title: 'Sin movimientos',
                      message:
                          controller.hasActiveFilters ||
                              controller.query.value.isNotEmpty
                          ? 'Prueba con otro periodo o cambia los filtros.'
                          : 'No hay cobros ni préstamos en este periodo.',
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: days.length,
                  separatorBuilder: (_, _) => SizedBox(height: gap),
                  itemBuilder: (_, i) => _DayGroup(
                    key: ValueKey(days[i].day),
                    day: days[i],
                    today: controller.today,
                    showPerson: !controller.onlyMine,
                    onOpen: controller.open,
                  ).entrance(i),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends GetView<MovementsController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En tablet/web el título ya está en la barra superior.
        if (context.isCompact)
          const Text(
            'Movimientos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                controller.onlyMine
                    ? 'Lo que has cobrado, prestado y gastado'
                    : 'Entradas y salidas de dinero del negocio',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const _ShareButton(),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => Get.toNamed(Routes.expenses),
              icon: const Icon(LucideIcons.receipt, size: 16),
              label: const Text('Gastos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Summary extends GetView<MovementsController> {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = controller.totals;
      final income = _Tile(
        icon: LucideIcons.arrowDownLeft,
        label: 'Entradas',
        value: t.income,
        caption: t.incomeCount == 1 ? '1 cobro' : '${t.incomeCount} cobros',
        color: AppColors.success,
        soft: AppColors.successSoft,
      );
      final outcome = _Tile(
        icon: LucideIcons.arrowUpRight,
        label: 'Salidas',
        value: t.outcome,
        caption: [
          t.loanCount == 1 ? '1 préstamo' : '${t.loanCount} préstamos',
          t.expenseCount == 1 ? '1 gasto' : '${t.expenseCount} gastos',
        ].join(' · '),
        color: _outColor,
        soft: _outSoft,
      );
      final net = _NetCard(totals: t);

      return LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          if (constraints.maxWidth >= 720) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: income),
                  const SizedBox(width: spacing),
                  Expanded(child: outcome),
                  const SizedBox(width: spacing),
                  Expanded(flex: 2, child: net),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: income),
                  const SizedBox(width: spacing),
                  Expanded(child: outcome),
                ],
              ),
              const SizedBox(height: spacing),
              net,
            ],
          );
        },
      );
    });
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.soft,
  });

  final IconData icon;
  final String label;
  final double value;
  final String caption;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.sized(12, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedNumber(
              value: value,
              format: Formatters.currency2,
              style: TextStyle(
                fontSize: context.sized(19, 22),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          Text(
            caption,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Neto del periodo y de dónde viene: efectivo / transferencia y el reparto
/// de lo cobrado.
class _NetCard extends StatelessWidget {
  const _NetCard({required this.totals});

  final MovementTotals totals;

  @override
  Widget build(BuildContext context) {
    final t = totals;
    final positive = t.net >= 0;
    const caption = TextStyle(color: Colors.white70, fontSize: 12.5);
    const strong = TextStyle(color: Colors.white, fontWeight: FontWeight.w800);

    return Container(
      padding: EdgeInsets.all(context.sized(14, 18)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Neto del periodo',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedNumber(
              value: t.net,
              format: (v) =>
                  '${v >= 0 ? '+' : '−'}${Formatters.currency2(v.abs())}',
              style: TextStyle(
                color: positive ? Colors.white : const Color(0xFFFFC9C9),
                fontSize: context.sized(24, 28),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _pair(LucideIcons.banknote, 'Efectivo', t.cash, caption, strong),
              _pair(
                LucideIcons.landmark,
                'Transferencia',
                t.transfer,
                caption,
                strong,
              ),
            ],
          ),
          if (t.income > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Cobrado: capital ${Formatters.currency2(t.capital)} · '
              'interés ${Formatters.currency2(t.interest)} · '
              'mora ${Formatters.currency2(t.lateFee)}',
              style: caption,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _pair(
    IconData icon,
    String label,
    double value,
    TextStyle caption,
    TextStyle strong,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: Colors.white70),
      const SizedBox(width: 5),
      Text('$label ', style: caption),
      Text(Formatters.currency2(value), style: strong.copyWith(fontSize: 13)),
    ],
  );
}

class _SearchBar extends GetView<MovementsController> {
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
                  hintText: 'Buscar cliente o número...',
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
                onPressed: () => FilterSheet.show(const _FiltersSheet()),
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

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  final controller = Get.find<MovementsController>();
  late final kinds = {...controller.kinds};
  late final methods = {...controller.methods};
  late final people = {...controller.people};

  void _toggle<T>(Set<T> set, T value) =>
      setState(() => set.contains(value) ? set.remove(value) : set.add(value));

  @override
  Widget build(BuildContext context) {
    final available = controller.availablePeople;

    return FilterSheet(
      onClear: controller.resetFilters,
      onApply: () => controller.applyFilters(
        kinds: kinds,
        methods: methods,
        people: people,
      ),
      sections: [
        FilterSection(
          label: 'Tipo',
          choices: [
            for (final k in MovementKind.values)
              FilterChoice(
                label: k.label,
                selected: kinds.contains(k),
                onTap: () => _toggle(kinds, k),
              ),
          ],
        ),
        FilterSection(
          label: 'Método de pago',
          choices: [
            for (final m in PaymentMethod.values)
              FilterChoice(
                label: m.label,
                selected: methods.contains(m),
                onTap: () => _toggle(methods, m),
              ),
          ],
        ),
        if (!controller.onlyMine && available.length > 1)
          FilterSection(
            label: 'Usuario',
            choices: [
              for (final (key, name) in available)
                FilterChoice(
                  label: name,
                  selected: people.contains(key),
                  onTap: () => _toggle(people, key),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    super.key,
    required this.day,
    required this.today,
    required this.showPerson,
    required this.onOpen,
  });

  final MovementDay day;
  final DateTime today;
  final bool showPerson;
  final ValueChanged<Movement> onOpen;

  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String get _label {
    final t = DateTime(today.year, today.month, today.day);
    final d = day.day;
    final date = DateFormat('dd/MM').format(d);
    if (d == t) return 'Hoy, $date';
    if (d == t.subtract(const Duration(days: 1))) return 'Ayer, $date';
    return '${_weekdays[d.weekday - 1]}, $date';
  }

  @override
  Widget build(BuildContext context) {
    final net = day.net;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _label,
                  style: TextStyle(
                    fontSize: context.sized(14, 15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${net >= 0 ? '+' : '−'}${Formatters.currency2(net.abs())}',
                style: TextStyle(
                  color: net >= 0 ? AppColors.success : _outColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < day.items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 64, color: AppColors.border),
                _MovementTile(
                  movement: day.items[i],
                  showPerson: showPerson,
                  onTap: () => onOpen(day.items[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.movement,
    required this.showPerson,
    required this.onTap,
  });

  final Movement movement;
  final bool showPerson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = movement;
    final expense = m.expense;
    final (color, soft, icon) = switch (m.kind) {
      MovementKind.payment => (
        AppColors.success,
        AppColors.successSoft,
        LucideIcons.arrowDownLeft,
      ),
      MovementKind.disbursement => (
        _outColor,
        _outSoft,
        LucideIcons.arrowUpRight,
      ),
      MovementKind.expense => (
        AppColors.danger,
        AppColors.dangerSoft,
        expense!.category.icon,
      ),
    };
    final when = '${m.reference} · ${_time.format(m.date)}';
    final how = [
      if (expense != null) expense.category.label,
      m.method?.label ?? 'Desembolso',
      if (showPerson && m.byName.isNotEmpty) m.byName,
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
              decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.sized(14.5, 15.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  for (final line in [when, how])
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
              '${m.isIncome ? '+' : '−'}${Formatters.currency2(m.amount)}',
              style: TextStyle(
                color: color,
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

/// Comparte o imprime el resumen de movimientos del periodo y filtros.
class _ShareButton extends GetView<MovementsController> {
  const _ShareButton();

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: 'Compartir o imprimir',
      onPressed: () => DocumentSheet.show(
        title: 'Resumen de movimientos',
        document: () => MovementsDoc(controller: controller),
        fileName: 'movimientos-${controller.period.value.name}',
        shareText:
            'Movimientos · '
            '${controller.period.value.describe(controller.today, controller.customRange.value)}',
      ),
      icon: const Icon(LucideIcons.share2, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
