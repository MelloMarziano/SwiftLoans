import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/company_settings_sync.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/form/form_fields.dart';
import '../../../core/widgets/form/form_section_card.dart';
import '../../../data/models/loan_terms.dart';
import '../widgets/settings_page.dart';

class LoanDefaultsController extends GetxController {
  final _s = Get.find<SettingsService>();

  late final frequency = _s.defaultFrequency.value.obs;
  late final type = _s.defaultType.value.obs;
  late final rate = TextEditingController(
    text: _s.defaultRate.value.toStringAsFixed(2),
  );
  late final lateFee = TextEditingController(
    text: _s.defaultLateFee.value.toStringAsFixed(2),
  );
  late final installments = TextEditingController(
    text: '${_s.defaultInstallments.value}',
  );
  late final closingCost = TextEditingController(
    text: _s.defaultClosingCost.value > 0
        ? MoneyInputFormatter.format(_s.defaultClosingCost.value)
        : '',
  );

  final errors = <String, String>{}.obs;

  @override
  void onClose() {
    for (final c in [rate, lateFee, installments, closingCost]) {
      c.dispose();
    }
    super.onClose();
  }

  void save() {
    final rateValue = double.tryParse(rate.text) ?? 0;
    final count = int.tryParse(installments.text) ?? 0;

    errors.assignAll({
      if (rateValue <= 0) 'rate': 'Ingresa la tasa',
      if (count < 1) 'installments': 'Mínimo 1',
    });
    if (errors.isNotEmpty) return;

    _s.defaultRate.value = rateValue;
    _s.defaultLateFee.value = double.tryParse(lateFee.text) ?? 0;
    _s.defaultInstallments.value = count;
    _s.defaultClosingCost.value = MoneyInputFormatter.parse(closingCost.text);
    _s.defaultFrequency.value = frequency.value;
    _s.defaultType.value = type.value;
    Get.back();
    showSettingsSaved('Se usarán en las próximas solicitudes.');
  }
}

class LoanDefaultsView extends GetView<LoanDefaultsController> {
  const LoanDefaultsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      readOnly: !CompanySettingsSync.canEdit,
      title: 'Préstamos por defecto',
      onSave: controller.save,
      children: [
        const Text(
          'Estos valores se llenan solos al crear una nueva solicitud. '
          'Siempre puedes cambiarlos en cada préstamo.',
        ),
        FormSectionCard(
          icon: LucideIcons.layers,
          title: 'Condiciones',
          child: Obx(
            () => FieldGrid(
              children: [
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
                  label: 'No. de cuotas',
                  controller: controller.installments,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  error: controller.errors['installments'],
                ),
                TextFieldBox(
                  icon: LucideIcons.percent,
                  label: 'Tasa mensual (%)',
                  controller: controller.rate,
                  inputFormatters: [DecimalInputFormatter()],
                  error: controller.errors['rate'],
                ),
                TextFieldBox(
                  icon: LucideIcons.chartNoAxesColumnIncreasing,
                  label: '% de mora',
                  controller: controller.lateFee,
                  hint: '0.00',
                  inputFormatters: [DecimalInputFormatter()],
                ),
                TextFieldBox.money(
                  icon: LucideIcons.receipt,
                  label: 'Gasto de cierre',
                  controller: controller.closingCost,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
