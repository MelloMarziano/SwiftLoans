import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/finance/loan_ledger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/form/field_box.dart';
import '../../core/widgets/form/form_fields.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../data/models/loan.dart';
import '../clients/widgets/client_status_chip.dart';
import '../root/widgets/app_shell.dart';
import 'collect_controller.dart';

class CollectView extends GetView<CollectController> {
  const CollectView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Aplicar pago',
      showBack: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 1000;
            final gap = context.sized(12, 20);

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                context.sized(14, 32),
                context.sized(14, 24),
                context.sized(14, 32),
                context.isCompact ? 120 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Obx(() {
                    final loan = controller.loan.value;
                    final client = controller.client.value;

                    final left = <Widget>[
                      const _ClientSelector(),
                      if (client != null && loan == null) ...[
                        SizedBox(height: gap),
                        const _NoLoanNotice(),
                      ],
                      if (loan != null) ...[
                        if (controller.clientLoans.length > 1) ...[
                          SizedBox(height: gap),
                          const _LoanSelector(),
                        ],
                        SizedBox(height: gap),
                        const _LoanStatusCard(),
                      ],
                    ];
                    final right = <Widget>[
                      if (loan != null) ...[
                        const _PaymentCard(),
                        SizedBox(height: gap),
                        const _AllocationCard(),
                        SizedBox(height: context.sized(16, 20)),
                      ],
                      const _ApplyButton(),
                    ];

                    if (twoColumns) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(children: left)),
                          SizedBox(width: gap),
                          Expanded(child: Column(children: right)),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...left,
                        SizedBox(height: gap),
                        ...right,
                      ],
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ClientSelector extends GetView<CollectController> {
  const _ClientSelector();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final client = controller.client.value;
      final style = FieldBox.valueStyle(context);

      return FieldBox(
        icon: LucideIcons.user,
        label: 'Cliente',
        required: true,
        error: controller.errorFor('client'),
        onTap: controller.pickClient,
        trailing: client == null
            ? const Icon(LucideIcons.chevronDown, size: 20)
            : ClientStatusChip(status: client.loanStatus),
        child: Text(
          client?.displayName ?? 'Selecciona un cliente',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: client == null
              ? style.copyWith(fontWeight: FontWeight.w700)
              : style,
        ),
      );
    });
  }
}

class _NoLoanNotice extends StatelessWidget {
  const _NoLoanNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.info, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(child: Text('Este cliente no tiene préstamos activos.')),
        ],
      ),
    );
  }
}

class _LoanSelector extends GetView<CollectController> {
  const _LoanSelector();

  @override
  Widget build(BuildContext context) {
    return SelectFieldBox<Loan>(
      icon: LucideIcons.layers,
      label: 'Préstamo',
      value: controller.loan.value!,
      options: controller.clientLoans,
      optionLabel: (l) => '${l.id} · ${Formatters.currency(l.amount)}',
      onChanged: controller.selectLoan,
    );
  }
}

class _LoanStatusCard extends GetView<CollectController> {
  const _LoanStatusCard();

  static final _date = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final loan = controller.loan.value!;
    final s = controller.snapshot!;
    final next = s.nextInstallment;

    final tiles = [
      _Stat(
        'Cuotas vencidas',
        '${s.overdueCount}',
        highlight: s.overdueCount > 0 ? AppColors.danger : null,
      ),
      _Stat(
        'Mora',
        Formatters.currency2(s.lateFeeDue),
        highlight: s.lateFeeDue > 0 ? AppColors.danger : null,
      ),
      _Stat('Cuota de hoy', Formatters.currency2(s.dueToday)),
      _Stat(
        'Para ponerse al día',
        Formatters.currency2(s.amountToBeCurrent),
        highlight: AppColors.primary,
      ),
      _Stat('Saldo total', Formatters.currency2(s.balance)),
      _Stat(
        'Próxima cuota',
        next == null ? '—' : '#${next.number} · ${_date.format(next.dueDate)}',
      ),
    ];

    return FormSectionCard(
      icon: LucideIcons.layers,
      title: 'Préstamo ${loan.id}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${Formatters.currency(loan.amount)} · ${loan.installments.length} '
            'cuotas ${loan.frequency.installmentsAdjective} · '
            '${loan.monthlyRate.toStringAsFixed(0)}% mensual · '
            'mora ${loan.lateFeeRate.toStringAsFixed(0)}%',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: context.sized(12.5, 14),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final width =
                  (constraints.maxWidth - 10 * (columns - 1)) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in tiles) SizedBox(width: width, child: t),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.highlight});

  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: context.sized(11.5, 13),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.sized(15, 17),
                fontWeight: FontWeight.w800,
                color: highlight ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends GetView<CollectController> {
  const _PaymentCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.banknote,
      title: 'Pago',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => TextFieldBox.money(
              icon: LucideIcons.dollarSign,
              label: 'Monto a pagar',
              required: true,
              controller: controller.amountController,
              error: controller.errorFor('amount'),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, value) in controller.quickAmounts)
                  ActionChip(
                    onPressed: () => controller.setAmount(value),
                    backgroundColor: AppColors.tile,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    label: Text.rich(
                      TextSpan(
                        text: '$label  ',
                        style: const TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: Formatters.currency2(value),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: context.sized(12.5, 13.5)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Método de pago',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: context.sized(12.5, 13.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Row(
              children: [
                for (final m in PaymentMethod.values) ...[
                  if (m != PaymentMethod.values.first)
                    const SizedBox(width: 10),
                  Expanded(
                    child: _MethodOption(
                      method: m,
                      selected: controller.method.value == m,
                      onTap: () => controller.method.value = m,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = method == PaymentMethod.cash
        ? LucideIcons.banknote
        : LucideIcons.arrowLeftRight;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accentSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: context.sized(46, 50),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  method.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista previa de cómo se reparte el pago (mora → interés → capital).
class _AllocationCard extends GetView<CollectController> {
  const _AllocationCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.listChecks,
      title: 'Cómo se aplica',
      child: Obx(() {
        final a = controller.allocation;
        final s = controller.snapshot;
        if (a == null || s == null) {
          return const Text(
            'Ingresa el monto para ver cómo se reparte.',
            style: TextStyle(color: AppColors.textSecondary),
          );
        }

        final completed = a.completed;
        final partial = a.items.where((i) => !i.completes).map((i) => i.number);
        final balanceAfter = LoanLedger.round(s.balance - a.total);

        Widget row(
          String label,
          double value, {
          bool bold = false,
          Color? color,
        }) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: bold
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                Formatters.currency2(value),
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  fontSize: bold ? 16 : 14,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(
              '1. Mora',
              a.lateFee,
              color: a.lateFee > 0 ? AppColors.danger : null,
            ),
            row('2. Interés', a.interest),
            row('3. Capital', a.capital),
            const Divider(height: 16, color: AppColors.border),
            row('Total aplicado', a.total, bold: true),
            row(
              'Saldo después del pago',
              balanceAfter,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            if (completed.isNotEmpty)
              _Note(
                icon: LucideIcons.circleCheck,
                color: AppColors.success,
                text: completed.length == 1
                    ? 'Salda la cuota #${completed.first}'
                    : 'Salda las cuotas #${completed.first} a #${completed.last} '
                          '(${completed.length})',
              ),
            if (partial.isNotEmpty)
              _Note(
                icon: LucideIcons.circleDashed,
                color: AppColors.primary,
                text: 'Abono parcial a la cuota #${partial.first}',
              ),
          ],
        );
      }),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
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

class _ApplyButton extends GetView<CollectController> {
  const _ApplyButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final saving = controller.isSaving.value;

      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: saving ? null : controller.applyPayment,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shadowColor: Colors.transparent,
            minimumSize: Size.fromHeight(context.sized(52, 58)),
            shape: const StadiumBorder(),
            textStyle: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: context.sized(16, 17),
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.banknote, size: 22),
          label: Text(saving ? 'Aplicando...' : 'Aplicar pago'),
        ),
      );
    });
  }
}
