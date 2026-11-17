import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/finance/loan_calculator.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/services/auth_backend.dart';
import '../../core/services/settings_service.dart';
import '../../data/models/client.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import 'widgets/client_picker_sheet.dart';

class LoanRequestController extends GetxController {
  final _settings = Get.find<SettingsService>();

  List<String> get routeOptions => _settings.routes;

  final client = Rxn<Client>();
  late final frequency = _settings.defaultFrequency.value.obs;
  late final type = _settings.defaultType.value.obs;
  late final installments = _settings.defaultInstallments.value.obs;
  final amount = 0.0.obs;
  late final monthlyRate = _settings.defaultRate.value.obs;
  late final lateFeeRate = _settings.defaultLateFee.value.obs;
  late final closingCost = _settings.defaultClosingCost.value.obs;
  final financeClosingCost = false.obs;
  late final route = routeOptions.first.obs;
  final startDate = DateUtils.dateOnly(DateTime.now()).obs;

  final quote = Rx<LoanQuote>(
    const LoanQuote(financedAmount: 0, periodRate: 0, schedule: []),
  );

  /// Los errores solo se muestran después del primer intento de guardar.
  final submitted = false.obs;
  final isSaving = false.obs;

  final amountController = TextEditingController();
  late final installmentsController = TextEditingController(
    text: '${_settings.defaultInstallments.value}',
  );
  late final rateController = TextEditingController(
    text: _settings.defaultRate.value.toStringAsFixed(2),
  );
  late final lateFeeController = TextEditingController(
    text: _settings.defaultLateFee.value > 0
        ? _settings.defaultLateFee.value.toStringAsFixed(2)
        : '',
  );
  late final closingCostController = TextEditingController(
    text: _settings.defaultClosingCost.value > 0
        ? MoneyInputFormatter.format(_settings.defaultClosingCost.value)
        : '',
  );

  @override
  void onInit() {
    super.onInit();
    // Desde la ficha del cliente llega ya seleccionado.
    if (Get.arguments is Client) client.value = Get.arguments as Client;
    amountController.addListener(
      () => amount.value = MoneyInputFormatter.parse(amountController.text),
    );
    closingCostController.addListener(
      () => closingCost.value = MoneyInputFormatter.parse(
        closingCostController.text,
      ),
    );
    rateController.addListener(
      () => monthlyRate.value = double.tryParse(rateController.text) ?? 0,
    );
    lateFeeController.addListener(
      () => lateFeeRate.value = double.tryParse(lateFeeController.text) ?? 0,
    );
    installmentsController.addListener(
      () => installments.value = int.tryParse(installmentsController.text) ?? 0,
    );

    everAll([
      amount,
      monthlyRate,
      installments,
      frequency,
      type,
      startDate,
      closingCost,
      financeClosingCost,
    ], (_) => _recalculate());
    _recalculate();
  }

  @override
  void onClose() {
    for (final c in [
      amountController,
      installmentsController,
      rateController,
      lateFeeController,
      closingCostController,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  Map<String, String> get _errors => {
    if (client.value == null) 'client': 'Selecciona un cliente',
    if (amount.value <= 0) 'amount': 'Ingresa el monto',
    if (installments.value < 1) 'installments': 'Mínimo 1',
    if (monthlyRate.value <= 0) 'rate': 'Ingresa la tasa',
  };

  String? errorFor(String field) => submitted.value ? _errors[field] : null;

  void changeInstallments(int delta) {
    final next = (installments.value + delta).clamp(1, 999);
    installmentsController.text = '$next';
  }

  Future<void> pickClient() async {
    final selected = await ClientPickerSheet.show(current: client.value);
    if (selected != null) client.value = selected;
  }

  Future<void> createClient() async {
    final created = await Get.toNamed(Routes.clientNew);
    if (created is Client) client.value = created;
  }

  Future<void> pickStartDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) startDate.value = picked;
  }

  void openSchedule() {
    if (quote.value.schedule.isEmpty) {
      Get.snackbar(
        'Faltan datos',
        'Ingresa el monto y el número de cuotas para ver el listado.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    Get.toNamed(Routes.loanSchedule, arguments: quote.value);
  }

  Future<void> save() async {
    submitted.value = true;
    if (_errors.isNotEmpty) {
      Get.snackbar(
        'Revisa la solicitud',
        _errors.values.join(' · '),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isSaving.value = true;
    final q = quote.value;
    try {
      final loan = await Get.find<LoanRepository>().createLoan(
        Loan(
          id: '',
          clientId: client.value!.id,
          amount: q.financedAmount,
          frequency: frequency.value,
          type: type.value,
          monthlyRate: monthlyRate.value,
          lateFeeRate: lateFeeRate.value,
          startDate: startDate.value,
          installments: q.schedule.map(LoanInstallment.fromSchedule).toList(),
          createdAt: DateTime.now(),
        ),
      );
      Get.back();
      Get.snackbar(
        'Préstamo ${loan.id} creado',
        '${Formatters.currency(q.financedAmount)} para ${client.value!.name} · '
            '${q.schedule.length} cuotas',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } on AuthFailure catch (e) {
      Get.snackbar(
        'No se pudo guardar',
        e.message,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _recalculate() {
    quote.value = LoanCalculator.quote(
      principal: amount.value,
      monthlyRatePercent: monthlyRate.value,
      installments: installments.value,
      frequency: frequency.value,
      type: type.value,
      startDate: startDate.value,
      closingCost: closingCost.value,
      financeClosingCost: financeClosingCost.value,
    );
  }
}
