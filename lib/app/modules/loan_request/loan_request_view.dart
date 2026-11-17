import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/form/field_box.dart';
import '../../core/widgets/form/form_fields.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../data/models/loan_terms.dart';
import '../root/root_controller.dart';
import '../root/widgets/app_shell.dart';
import 'loan_request_controller.dart';
import 'widgets/request_actions.dart';

class LoanRequestView extends GetView<LoanRequestController> {
  const LoanRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Nueva solicitud',
      showBack: true,
      activeTab: RootController.loans,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = context.isCompact;
            final twoColumns = constraints.maxWidth >= 1000;
            final gap = context.sized(12, 20);

            final details = _LoanDetailsCard();
            final conditions = _FinancialConditionsCard();
            const extras = _AdditionalCard();
            final actions = const RequestActions();

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                context.sized(14, 32),
                context.sized(14, 24),
                context.sized(14, 32),
                compact ? 120 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      SizedBox(height: gap),
                      const _ClientSelector(),
                      SizedBox(height: gap),
                      if (twoColumns)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  details,
                                  SizedBox(height: gap),
                                  conditions,
                                ],
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: Column(
                                children: [
                                  extras,
                                  SizedBox(height: gap),
                                  actions,
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        details,
                        SizedBox(height: gap),
                        conditions,
                        SizedBox(height: gap),
                        extras,
                        SizedBox(height: gap),
                        actions,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final size = context.sized(48.0, 56.0);

    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(
            LucideIcons.filePlus,
            size: size * 0.5,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registra una solicitud de préstamo',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClientSelector extends GetView<LoanRequestController> {
  const _ClientSelector();

  @override
  Widget build(BuildContext context) {
    final buttonSize = context.sized(56.0, 64.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Obx(() {
            final client = controller.client.value;
            final style = FieldBox.valueStyle(context);

            return FieldBox(
              icon: LucideIcons.user,
              label: 'Cliente',
              required: true,
              error: controller.errorFor('client'),
              onTap: controller.pickClient,
              trailing: const Icon(LucideIcons.chevronDown, size: 20),
              child: Text(
                client?.displayName ?? 'Selecciona un cliente',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: client == null
                    ? style.copyWith(fontWeight: FontWeight.w700)
                    : style,
              ),
            );
          }),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Nuevo cliente',
          child: Material(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: controller.createClient,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: const Icon(LucideIcons.plus, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoanDetailsCard extends GetView<LoanRequestController> {
  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.layers,
      title: 'Detalles del préstamo',
      child: Obx(
        () => FieldGrid(
          children: [
            TextFieldBox.money(
              icon: LucideIcons.dollarSign,
              label: 'Monto solicitado',
              required: true,
              controller: controller.amountController,
              error: controller.errorFor('amount'),
            ),
            SelectFieldBox<PaymentFrequency>(
              icon: LucideIcons.calendar,
              label: 'Frecuencia',
              value: controller.frequency.value,
              options: PaymentFrequency.values,
              optionLabel: (f) => f.label,
              onChanged: (f) => controller.frequency.value = f,
            ),
            SelectFieldBox<LoanType>(
              icon: LucideIcons.coins,
              label: 'Tipo de préstamo',
              value: controller.type.value,
              options: LoanType.values,
              optionLabel: (t) => t.label,
              onChanged: (t) => controller.type.value = t,
            ),
            TextFieldBox(
              icon: LucideIcons.timer,
              label: 'No. de ${controller.frequency.value.periodName}',
              controller: controller.installmentsController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              error: controller.errorFor('installments'),
              trailing: _Stepper(
                onUp: () => controller.changeInstallments(1),
                onDown: () => controller.changeInstallments(-1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialConditionsCard extends GetView<LoanRequestController> {
  static final _date = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.percent,
      title: 'Condiciones financieras',
      child: Obx(
        () => FieldGrid(
          children: [
            FieldBox(
              icon: LucideIcons.database,
              label: 'Monto de la cuota',
              readOnly: true,
              child: Text(
                Formatters.currency2(controller.quote.value.payment),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FieldBox.valueStyle(context),
              ),
            ),
            TextFieldBox(
              icon: LucideIcons.creditCard,
              label: 'Tasa mensual (%)',
              controller: controller.rateController,
              inputFormatters: [DecimalInputFormatter()],
              hint: '0.00',
              error: controller.errorFor('rate'),
            ),
            TextFieldBox(
              icon: LucideIcons.chartNoAxesColumnIncreasing,
              label: '% de mora (opcional)',
              controller: controller.lateFeeController,
              inputFormatters: [DecimalInputFormatter()],
              hint: '0.00',
            ),
            FieldBox(
              icon: LucideIcons.calendar,
              label: 'Fecha de inicio',
              onTap: () => controller.pickStartDate(context),
              trailing: const Icon(
                LucideIcons.calendarDays,
                size: 20,
                color: AppColors.textSecondary,
              ),
              child: Text(
                _date.format(controller.startDate.value),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: FieldBox.valueStyle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdditionalCard extends GetView<LoanRequestController> {
  const _AdditionalCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.mapPin,
      title: 'Adicionales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => SelectFieldBox<String>(
              icon: LucideIcons.mapPin,
              label: 'Ruta / Oficina',
              value: controller.route.value,
              options: controller.routeOptions,
              optionLabel: (r) => r,
              onChanged: (r) => controller.route.value = r,
            ),
          ),
          const SizedBox(height: 10),
          TextFieldBox.money(
            icon: LucideIcons.receipt,
            label: 'Gasto de cierre',
            controller: controller.closingCostController,
          ),
          const SizedBox(height: 4),
          Obx(
            () => Row(
              children: [
                Checkbox(
                  value: controller.financeClosingCost.value,
                  onChanged: (v) =>
                      controller.financeClosingCost.value = v ?? false,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Flexible(
                  child: GestureDetector(
                    onTap: () => controller.financeClosingCost.toggle(),
                    child: Text(
                      'Financiar gasto de cierre',
                      style: TextStyle(
                        fontSize: context.sized(14, 15),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: Duration(seconds: 4),
                  message:
                      'Suma el gasto de cierre al monto del préstamo en lugar '
                      'de cobrarlo al momento del desembolso.',
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.info,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
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

class _Stepper extends StatelessWidget {
  const _Stepper({required this.onUp, required this.onDown});

  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback onTap, String label) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Icon(icon, size: 16, semanticLabel: label),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(LucideIcons.chevronUp, onUp, 'Aumentar'),
        button(LucideIcons.chevronDown, onDown, 'Disminuir'),
      ],
    );
  }
}
