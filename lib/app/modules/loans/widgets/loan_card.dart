import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/motion.dart';
import '../loans_controller.dart';
import 'loan_status_chip.dart';

/// Tarjeta de la lista de préstamos: cliente, avance, próxima cuota y un
/// botón para cobrar sin abrir el detalle.
class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.row,
    required this.onTap,
    required this.onCollect,
    this.selected = false,
  });

  final LoanRow row;
  final VoidCallback onTap;
  final VoidCallback onCollect;
  final bool selected;

  static final _date = DateFormat('dd/MM/yy');

  @override
  Widget build(BuildContext context) {
    final loan = row.loan;
    final s = row.snapshot;
    final radius = BorderRadius.circular(20);
    final (_, _, statusColor) = LoanStatusChip.styleOf(row.status);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF2FBFC) : AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(context.sized(14, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.sized(15, 16),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${loan.id} · ${loan.frequency.label} · '
                            '${row.paidCount}/${loan.installments.length} cuotas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: context.sized(12.5, 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LoanStatusChip(status: row.status),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBar(
                  value: row.progress,
                  height: 7,
                  color: row.status == LoanStatus.overdue
                      ? AppColors.danger
                      : AppColors.primary,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Debe '),
                                TextSpan(
                                  text: Formatters.currency2(s.balance),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' · prestó ${Formatters.currency(loan.amount)}',
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: context.sized(13.5, 14.5),
                            ),
                          ),
                          Text(
                            _nextText(row),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: row.status == LoanStatus.upToDate
                                  ? AppColors.textSecondary
                                  : statusColor,
                              fontSize: context.sized(12.5, 13.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (row.status != LoanStatus.paidOff) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onCollect,
                        icon: const Icon(LucideIcons.banknote, size: 16),
                        label: const Text('Cobrar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: const StadiumBorder(),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _nextText(LoanRow row) {
    final s = row.snapshot;
    final next = s.nextInstallment;
    return switch (row.status) {
      LoanStatus.paidOff => 'Préstamo saldado',
      LoanStatus.overdue =>
        'Atrasado ${s.overdueCount} '
            '${s.overdueCount == 1 ? 'cuota' : 'cuotas'}'
            '${s.lateFeeDue > 0 ? ' · mora ${Formatters.currency2(s.lateFeeDue)}' : ''}',
      LoanStatus.dueToday => 'Cobrar hoy: ${Formatters.currency2(s.dueToday)}',
      LoanStatus.upToDate =>
        next == null
            ? ''
            : 'Próxima: ${_date.format(next.dueDate)} · '
                  '${Formatters.currency2(next.pending)}',
    };
  }
}
