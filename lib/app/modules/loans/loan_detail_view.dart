import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/finance/loan_ledger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/client.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../root/root_controller.dart';
import '../documents/document_actions.dart';
import '../documents/documents.dart';
import '../root/widgets/app_shell.dart';
import 'loans_controller.dart';
import 'widgets/loan_status_chip.dart';

final _date = DateFormat('dd/MM/yyyy');

/// Detalle de un préstamo en su propia pantalla (móvil y tablet). Recibe el
/// ID del préstamo como argumento.
class LoanDetailView extends StatelessWidget {
  const LoanDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.arguments as String?;

    return AppShell(
      title: 'Préstamo ${id ?? ''}',
      showBack: true,
      activeTab: RootController.loans,
      body: id == null
          ? const _NotFound()
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.sized(14, 32),
                context.sized(14, 24),
                context.sized(14, 32),
                context.isCompact ? 120 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: LoanDetailPanel(loanId: id),
                ),
              ),
            ),
    );
  }
}

/// Contenido del detalle: resumen, acciones, datos, cuotas y pagos. Se usa
/// en la pantalla de detalle y al lado de la lista en pantallas anchas.
class LoanDetailPanel extends StatelessWidget {
  const LoanDetailPanel({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context) {
    final loans = Get.find<LoanRepository>();
    final clients = Get.find<ClientRepository>();

    return Obx(() {
      final loan = loans.loanById(loanId);
      if (loan == null) return const _NotFound();
      final row = LoanRow(
        loan: loan,
        client: clients.byId(loan.clientId),
        today: loans.today,
      );
      final payments = loans.paymentsOfLoan(loanId);
      final gap = context.sized(12.0, 16.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Overview(row: row),
          SizedBox(height: gap),
          _Actions(row: row),
          SizedBox(height: gap),
          _Terms(loan: loan),
          SizedBox(height: gap),
          _Installments(loan: loan, today: loans.today),
          SizedBox(height: gap),
          _Payments(payments: payments),
        ],
      );
    });
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: LucideIcons.fileX,
      title: 'Préstamo no encontrado',
      message: 'Es posible que ya no exista en esta empresa.',
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.row});

  final LoanRow row;

  @override
  Widget build(BuildContext context) {
    final loan = row.loan;
    final s = row.snapshot;
    final paid = loan.totalDue * row.progress;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        fontSize: context.sized(18, 21),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Préstamo ${loan.id} · ${loan.frequency.label}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              LoanStatusChip(status: row.status),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Saldo pendiente',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          AnimatedNumber(
            value: s.balance,
            format: Formatters.currency2,
            style: TextStyle(
              fontSize: context.sized(26, 30),
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBar(
            value: row.progress,
            height: 9,
            color: row.status == LoanStatus.overdue
                ? AppColors.danger
                : AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Pagado ${Formatters.currency2(paid)} de '
            '${Formatters.currency2(loan.totalDue)} · '
            '${row.paidCount}/${loan.installments.length} cuotas',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: context.sized(12.5, 13.5),
            ),
          ),
          if (s.overdueCount > 0) ...[
            const SizedBox(height: 12),
            _Notice(
              icon: LucideIcons.clockAlert,
              color: AppColors.danger,
              background: AppColors.dangerSoft,
              text:
                  '${s.overdueCount} '
                  '${s.overdueCount == 1 ? 'cuota vencida' : 'cuotas vencidas'}'
                  ' · mora ${Formatters.currency2(s.lateFeeDue)} · '
                  'para ponerse al día: ${Formatters.currency2(s.amountToBeCurrent)}',
            ),
          ] else if (s.dueToday > 0) ...[
            const SizedBox(height: 12),
            _Notice(
              icon: LucideIcons.coins,
              color: AppColors.success,
              background: AppColors.successSoft,
              text: 'Hoy toca cobrar ${Formatters.currency2(s.dueToday)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.row});

  final LoanRow row;

  @override
  Widget build(BuildContext context) {
    final Client? client = row.client;
    final outlined = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      minimumSize: Size.fromHeight(context.sized(46, 50)),
      shape: const StadiumBorder(),
      textStyle: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: context.sized(13.5, 14.5),
        fontWeight: FontWeight.w800,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (row.status != LoanStatus.paidOff) ...[
          FilledButton.icon(
            onPressed: () => Get.toNamed(Routes.collect, arguments: row.loan),
            icon: const Icon(LucideIcons.banknote, size: 20),
            label: const Text('Cobrar'),
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
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => DocumentSheet.show(
                  title: 'Estado de cuenta',
                  document: () => LoanStatementDoc(loanId: row.loan.id),
                  fileName: 'estado-cuenta-${row.loan.id}',
                  shareText:
                      'Estado de cuenta ${row.loan.id} · ${row.clientName}',
                ),
                icon: const Icon(LucideIcons.fileText, size: 18),
                label: Text(context.isCompact ? 'Estado' : 'Estado de cuenta'),
                style: outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: client == null
                    ? null
                    : () => Get.toNamed(
                        Routes.clientDetail,
                        arguments: client.id,
                      ),
                icon: const Icon(LucideIcons.user, size: 18),
                label: const Text('Ver cliente'),
                style: outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Terms extends StatelessWidget {
  const _Terms({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final interest = loan.installments.fold<double>(
      0,
      (s, i) => s + i.interest,
    );
    final rows = <(String, String)>[
      ('Monto prestado', Formatters.currency2(loan.amount)),
      ('Tipo', loan.type.label),
      ('Tasa', '${_num(loan.monthlyRate)}% mensual'),
      ('Mora', '${_num(loan.lateFeeRate)}% por cuota vencida'),
      (
        'Cuotas',
        '${loan.installments.length} ${loan.frequency.installmentsAdjective}',
      ),
      ('Interés total', Formatters.currency2(interest)),
      ('Total a pagar', Formatters.currency2(loan.totalDue)),
      ('Inicio', _date.format(loan.startDate)),
      if (loan.installments.isNotEmpty)
        ('Termina', _date.format(loan.installments.last.dueDate)),
    ];

    return FormSectionCard(
      icon: LucideIcons.fileText,
      title: 'Datos del préstamo',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // En pantallas anchas, dos columnas de datos.
          final columns = constraints.maxWidth >= 560 ? 2 : 1;
          final width = (constraints.maxWidth - 24 * (columns - 1)) / columns;
          return Wrap(
            spacing: 24,
            children: [
              for (final (label, value) in rows)
                SizedBox(
                  width: width,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: context.sized(13, 14),
                            ),
                          ),
                        ),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: context.sized(14, 15),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

enum _InstallmentState {
  paid('Pagada', AppColors.success, AppColors.successSoft),
  overdue('Vencida', AppColors.danger, AppColors.dangerSoft),
  today('Hoy', AppColors.success, AppColors.successSoft),
  partial('Parcial', Color(0xFFB7791F), Color(0xFFFBF0DC)),
  pending('Pendiente', AppColors.textSecondary, Color(0xFFEFF3F4));

  const _InstallmentState(this.label, this.color, this.background);
  final String label;
  final Color color;
  final Color background;
}

class _Installments extends StatelessWidget {
  const _Installments({required this.loan, required this.today});

  final Loan loan;
  final DateTime today;

  _InstallmentState _stateOf(LoanInstallment i) {
    if (i.isPaid) return _InstallmentState.paid;
    if (LoanLedger.isOverdue(i, today)) return _InstallmentState.overdue;
    final d = i.dueDate;
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return _InstallmentState.today;
    }
    if (i.paidInterest + i.paidCapital > 0) return _InstallmentState.partial;
    return _InstallmentState.pending;
  }

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.calendarDays,
      title: 'Cuotas',
      child: Column(
        children: [
          for (var n = 0; n < loan.installments.length; n++) ...[
            if (n > 0) const Divider(height: 1, color: AppColors.border),
            _InstallmentTile(
              installment: loan.installments[n],
              state: _stateOf(loan.installments[n]),
              lateFee: LoanLedger.lateFeeFor(loan, loan.installments[n], today),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({
    required this.installment,
    required this.state,
    required this.lateFee,
  });

  final LoanInstallment installment;
  final _InstallmentState state;

  /// Mora pendiente de la cuota.
  final double lateFee;

  @override
  Widget build(BuildContext context) {
    final i = installment;
    final paid = i.paidInterest + i.paidCapital;
    final details = [
      if (state == _InstallmentState.paid)
        'Capital ${Formatters.currency2(i.capital)} · '
            'interés ${Formatters.currency2(i.interest)}'
      else ...[
        if (paid > 0) 'Pagado ${Formatters.currency2(paid)}',
        'Falta ${Formatters.currency2(i.pending)}',
      ],
      if (lateFee > 0) 'Mora ${Formatters.currency2(lateFee)}',
      if (i.paidLateFee > 0)
        'Mora pagada ${Formatters.currency2(i.paidLateFee)}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: state.background,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${i.number}',
              style: TextStyle(
                color: state.color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_date.format(i.dueDate)} · ${Formatters.currency2(i.payment)}',
                  style: TextStyle(
                    fontSize: context.sized(14, 15),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  details.join(' · '),
                  style: TextStyle(
                    color: lateFee > 0
                        ? AppColors.danger
                        : AppColors.textSecondary,
                    fontSize: context.sized(12, 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: state.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              state.label,
              style: TextStyle(
                color: state.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Payments extends StatelessWidget {
  const _Payments({required this.payments});

  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.receiptText,
      title: 'Pagos (${payments.length})',
      child: payments.isEmpty
          ? const Text(
              'Aún no tiene pagos.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: [
                for (final p in payments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () =>
                        Get.toNamed(Routes.paymentReceipt, arguments: p.id),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.successSoft,
                      child: Icon(
                        LucideIcons.circleCheck,
                        size: 18,
                        color: AppColors.success,
                      ),
                    ),
                    title: Text(
                      Formatters.currency2(p.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${p.id} · ${_date.format(p.date)} · ${p.method.label}'
                      '${p.collector.isEmpty ? '' : ' · ${p.collector}'}',
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  ),
              ],
            ),
    );
  }
}
