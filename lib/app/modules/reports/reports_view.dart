import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../core/widgets/period_chips.dart';
import '../expenses/widgets/expense_category_style.dart';
import '../home/widgets/weekly_bar_chart.dart';
import '../documents/document_actions.dart';
import '../documents/documents.dart';
import 'reports_controller.dart';

const _outColor = Color(0xFFB7791F);
const _outSoft = Color(0xFFFBF0DC);

/// Reportes: resultados del periodo, efectividad de cobro, cartera y
/// desempeño por usuario.
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          compact ? 14.0 : 32.0,
          (constraints.maxWidth - 1200) / 2,
        );
        final gap = context.sized(14.0, 20.0);
        final twoColumns = constraints.maxWidth >= 1000;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(side, gap, side, compact ? 120 : 32),
          child: Obx(() {
            // Las tarjetas no son const: se reconstruyen con cada dato nuevo.
            controller.watch();
            final left = <Widget>[
              _FlowCard(),
              _EffectivenessCard(),
              if (!controller.onlyMine) _PeopleCard(),
            ];
            final right = <Widget>[
              _PortfolioCard(),
              _OverdueCard(),
              _ExpensesCard(),
            ];

            Widget column(List<Widget> items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  items[i].entrance(i + 1),
                ],
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                SizedBox(height: gap),
                PeriodChips(
                  period: controller.period,
                  customRange: controller.customRange,
                  today: controller.today,
                ),
                SizedBox(height: gap),
                _Kpis().entrance(),
                SizedBox(height: gap),
                if (twoColumns)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: column(left)),
                      SizedBox(width: gap),
                      Expanded(child: column(right)),
                    ],
                  )
                else
                  column([...left, ...right]),
              ],
            );
          }),
        );
      },
    );
  }
}

class _Header extends GetView<ReportsController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En tablet/web el título ya está en la barra superior.
        if (context.isCompact)
          const Text(
            'Reportes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                controller.onlyMine
                    ? 'Tus resultados y el estado de la cartera'
                    : 'Resultados del negocio y estado de la cartera',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => DocumentSheet.show(
                title: 'Reporte',
                document: () => ReportDoc(controller: controller),
                fileName: 'reporte-${controller.period.value.name}',
                shareText:
                    'Reporte · ${controller.period.value.describe(controller.today, controller.customRange.value)}',
              ),
              icon: const Icon(LucideIcons.share2, size: 16),
              label: const Text('Compartir'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
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

class _Kpis extends GetView<ReportsController> {
  const _Kpis();

  @override
  Widget build(BuildContext context) {
    final profit = controller.profit;
    final tiles = [
      _Kpi(
        icon: LucideIcons.arrowDownLeft,
        label: 'Cobrado',
        value: controller.collected,
        caption: '${controller.periodPayments.length} cobros',
        color: AppColors.success,
        soft: AppColors.successSoft,
      ),
      _Kpi(
        icon: LucideIcons.handCoins,
        label: 'Prestado',
        value: controller.disbursed,
        caption: '${controller.periodLoans.length} préstamos',
        color: _outColor,
        soft: _outSoft,
      ),
      _Kpi(
        icon: LucideIcons.receipt,
        label: 'Gastos',
        value: controller.spent,
        caption: '${controller.periodExpenses.length} gastos',
        color: AppColors.danger,
        soft: AppColors.dangerSoft,
      ),
      _Kpi(
        icon: LucideIcons.trendingUp,
        label: 'Ganancia',
        value: profit,
        caption: 'interés + mora − gastos',
        color: profit < 0 ? AppColors.danger : AppColors.primary,
        soft: AppColors.accentSoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
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
              format: (v) =>
                  '${v < 0 ? '−' : ''}${Formatters.currency2(v.abs())}',
              style: TextStyle(
                fontSize: context.sized(18, 22),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _FlowCard extends GetView<ReportsController> {
  const _FlowCard();

  @override
  Widget build(BuildContext context) {
    final data = controller.flow;

    return FormSectionCard(
      icon: LucideIcons.chartNoAxesColumn,
      title: 'Cobros vs. préstamos',
      child: data.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Elige un periodo de varios días para ver el gráfico.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _Legend(color: AppColors.primary, label: 'Cobros'),
                    SizedBox(width: 16),
                    _Legend(color: AppColors.accent, label: 'Préstamos'),
                  ],
                ),
                const SizedBox(height: 16),
                WeeklyBarChart(data: data, onSelect: (_) {}, height: 160),
              ],
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _EffectivenessCard extends GetView<ReportsController> {
  const _EffectivenessCard();

  @override
  Widget build(BuildContext context) {
    final (expected, paid) = controller.collectionEffectiveness;
    final ratio = expected == 0 ? 0.0 : (paid / expected).clamp(0.0, 1.0);
    final color = ratio >= 0.9
        ? AppColors.success
        : ratio >= 0.7
        ? _outColor
        : AppColors.danger;

    return FormSectionCard(
      icon: LucideIcons.target,
      title: 'Efectividad de cobro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            expected == 0 ? '—' : Formatters.percent(ratio),
            style: TextStyle(
              color: color,
              fontSize: context.sized(26, 30),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBar(value: ratio, height: 9, color: color),
          const SizedBox(height: 8),
          Text(
            expected == 0
                ? 'No vencieron cuotas en este periodo.'
                : 'Pagado ${Formatters.currency2(paid)} de '
                      '${Formatters.currency2(expected)} en cuotas que '
                      'vencían en el periodo.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Divider(height: 24, color: AppColors.border),
          _Line('Capital cobrado', controller.collectedCapital),
          _Line('Interés cobrado', controller.collectedInterest),
          _Line('Mora cobrada', controller.collectedLateFee),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            Formatters.currency2(value),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends GetView<ReportsController> {
  const _PortfolioCard();

  static const _colors = {
    AgingBucket.current: AppColors.primary,
    AgingBucket.low: Color(0xFFE0A100),
    AgingBucket.mid: _outColor,
    AgingBucket.high: AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final total = controller.portfolio;
    final rows = controller.aging;
    final risk = controller.atRiskRatio;

    return FormSectionCard(
      icon: LucideIcons.wallet,
      title: 'Cartera (a hoy)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  Formatters.currency2(total),
                  style: TextStyle(
                    fontSize: context.sized(22, 26),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${Formatters.percent(risk)} en atraso',
                style: TextStyle(
                  color: risk > 0.15
                      ? AppColors.danger
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra apilada por tramo de atraso.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final r in rows)
                    if (r.balance > 0)
                      Expanded(
                        flex: math.max(1, (r.balance / total * 1000).round()),
                        child: Container(color: _colors[r.bucket]),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colors[r.bucket],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.bucket.label)),
                  Text(
                    '${r.count} ${r.count == 1 ? 'préstamo' : 'préstamos'}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: context.sized(84, 110),
                    child: Text(
                      Formatters.currency(r.balance),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OverdueCard extends GetView<ReportsController> {
  const _OverdueCard();

  @override
  Widget build(BuildContext context) {
    final rows = controller.mostOverdue;

    return FormSectionCard(
      icon: LucideIcons.clockAlert,
      title: 'Más atrasados',
      child: rows.isEmpty
          ? const Text(
              'No hay préstamos atrasados.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: [
                for (final r in rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => controller.openLoan(r.loan),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.dangerSoft,
                      child: Icon(
                        LucideIcons.clockAlert,
                        size: 18,
                        color: AppColors.danger,
                      ),
                    ),
                    title: Text(
                      r.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${r.loan.id} · ${r.overdueCount} '
                      '${r.overdueCount == 1 ? 'cuota' : 'cuotas'}',
                    ),
                    trailing: Text(
                      Formatters.currency2(r.overdueAmount),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PeopleCard extends GetView<ReportsController> {
  const _PeopleCard();

  @override
  Widget build(BuildContext context) {
    final rows = controller.byPerson;
    final top = rows.isEmpty ? 0.0 : rows.first.collected;

    return FormSectionCard(
      icon: LucideIcons.users,
      title: 'Por usuario',
      child: rows.isEmpty
          ? const Text(
              'Sin cobros ni gastos en este periodo.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: [
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              Formatters.currency2(r.collected),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedBar(
                          value: top == 0 ? 0 : r.collected / top,
                          height: 6,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${r.payments} cobros · gastos '
                          '${Formatters.currency2(r.expenses)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ExpensesCard extends GetView<ReportsController> {
  const _ExpensesCard();

  @override
  Widget build(BuildContext context) {
    final rows = controller.expensesByCategory;
    final total = controller.spent;

    return FormSectionCard(
      icon: LucideIcons.receipt,
      title: 'Gastos por categoría',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rows.isEmpty)
            const Text(
              'Sin gastos en este periodo.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final (category, amount) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(category.label)),
                    Text(
                      Formatters.percent(total == 0 ? 0 : amount / total),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: context.sized(76, 100),
                      child: Text(
                        Formatters.currency(amount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: controller.openExpenses,
              icon: const Icon(LucideIcons.arrowRight, size: 16),
              label: const Text('Ver gastos'),
            ),
          ),
        ],
      ),
    );
  }
}
