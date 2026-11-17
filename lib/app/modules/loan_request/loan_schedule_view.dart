import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/finance/loan_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/loan_terms.dart';
import '../root/root_controller.dart';
import '../root/widgets/app_shell.dart';

/// Tabla de amortización de la solicitud. Recibe el [LoanQuote] como argumento.
class LoanScheduleView extends StatelessWidget {
  const LoanScheduleView({super.key});

  static final _date = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final quote = Get.arguments as LoanQuote?;
    final side = context.sized(14, 32);

    return AppShell(
      title: 'Listado de cuotas',
      showBack: true,
      activeTab: RootController.loans,
      body: quote == null || quote.schedule.isEmpty
          ? const EmptyState(
              icon: LucideIcons.list,
              title: 'Sin cuotas',
              message: 'Completa la solicitud para generar el listado.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        side,
                        context.sized(14, 24),
                        side,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_Summary(quote: quote)],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        side,
                        context.sized(12, 16),
                        side,
                        context.isCompact ? 120 : 32,
                      ),
                      sliver: SliverList.separated(
                        itemCount: quote.schedule.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _InstallmentTile(installment: quote.schedule[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.quote});

  final LoanQuote quote;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Monto financiado', Formatters.currency2(quote.financedAmount)),
      ('Interés total', Formatters.currency2(quote.totalInterest)),
      ('Total a pagar', Formatters.currency2(quote.totalPayment)),
      ('Cuota', Formatters.currency2(quote.payment)),
    ];

    return SectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560 ? 4 : 2;
          final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;

          return Wrap(
            spacing: 12,
            runSpacing: 14,
            children: [
              for (final (label, value) in items)
                SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: context.sized(12, 13),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: context.sized(16, 18),
                            fontWeight: FontWeight.w800,
                            color: label == 'Total a pagar'
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.installment});

  final Installment installment;

  @override
  Widget build(BuildContext context) {
    final i = installment;
    final badge = context.sized(36.0, 42.0);
    final meta = TextStyle(
      color: AppColors.textSecondary,
      fontSize: context.sized(11.5, 13),
    );

    return Container(
      padding: EdgeInsets.all(context.sized(12, 14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: badge,
            height: badge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(badge * 0.3),
            ),
            child: Text(
              '${i.number}',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        LoanScheduleView._date.format(i.dueDate),
                        style: TextStyle(
                          fontSize: context.sized(14, 15),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.currency2(i.payment),
                      style: TextStyle(
                        fontSize: context.sized(15, 16),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Capital ${Formatters.currency2(i.capital)} · '
                        'Interés ${Formatters.currency2(i.interest)}',
                        style: meta,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saldo ${Formatters.currency2(i.balance)}',
                      style: meta,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
