import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/finance/loan_ledger.dart';
import '../../core/services/auth_backend.dart';
import '../../core/services/printer_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/client.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../documents/document_actions.dart';
import '../documents/documents.dart';
import '../loan_request/widgets/client_picker_sheet.dart';

/// Monto sugerido con su etiqueta ("Cuota", "Ponerse al día", "Saldo total").
typedef QuickAmount = (String label, double value);

class CollectController extends GetxController {
  final _loans = Get.find<LoanRepository>();

  final client = Rxn<Client>();
  final loan = Rxn<Loan>();
  final method = PaymentMethod.cash.obs;
  final amount = 0.0.obs;
  final submitted = false.obs;
  final isSaving = false.obs;

  final amountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(
      () => amount.value = MoneyInputFormatter.parse(amountController.text),
    );
    // Desde la ficha del cliente o desde Préstamos llega ya seleccionado.
    final args = Get.arguments;
    if (args is Client) selectClient(args);
    if (args is Loan) {
      final owner = Get.find<ClientRepository>().byId(args.clientId);
      if (owner != null) selectClient(owner);
      selectLoan(_loans.loanById(args.id) ?? args);
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  DateTime get today => _loans.today;

  List<Loan> get clientLoans =>
      client.value == null ? const [] : _loans.activeLoansOf(client.value!.id);

  LoanSnapshot? get snapshot =>
      loan.value == null ? null : LoanLedger.snapshot(loan.value!, today);

  PaymentAllocation? get allocation => loan.value == null || amount.value <= 0
      ? null
      : LoanLedger.allocate(loan.value!, amount.value, today);

  List<QuickAmount> get quickAmounts {
    final s = snapshot;
    final next = s?.nextInstallment;
    if (s == null || next == null) return const [];

    final installment =
        next.pending + LoanLedger.lateFeeFor(loan.value!, next, today);
    return [
      ('Cuota', installment),
      if (s.amountToBeCurrent > installment)
        ('Ponerse al día', s.amountToBeCurrent),
      ('Saldo total', s.balance),
    ];
  }

  Future<void> pickClient() async {
    final selected = await ClientPickerSheet.show(
      current: client.value,
      title: '¿A quién vas a cobrar?',
      filter: (c) => c.hasLoan,
    );
    if (selected != null) selectClient(selected);
  }

  void selectClient(Client value) {
    client.value = value;
    final loans = _loans.activeLoansOf(value.id);
    selectLoan(loans.isEmpty ? null : loans.first);
  }

  /// Al cambiar de préstamo se sugiere el monto para ponerse al día
  /// (o la próxima cuota si ya está al día).
  void selectLoan(Loan? value) {
    loan.value = value;
    final s = snapshot;
    if (s == null) {
      amountController.clear();
      return;
    }
    final suggested = s.amountToBeCurrent > 0
        ? s.amountToBeCurrent
        : quickAmounts.first.$2;
    setAmount(suggested);
  }

  void setAmount(double value) =>
      amountController.text = MoneyInputFormatter.format(value);

  Map<String, String> get _errors {
    final s = snapshot;
    return {
      if (client.value == null) 'client': 'Selecciona un cliente',
      if (client.value != null && loan.value == null)
        'loan': 'El cliente no tiene préstamos activos',
      if (amount.value <= 0) 'amount': 'Ingresa el monto',
      if (s != null && amount.value > s.balance)
        'amount': 'Supera el saldo total (${Formatters.currency2(s.balance)})',
    };
  }

  String? errorFor(String field) {
    amount.value; // registra la dependencia para refrescar en vivo
    return submitted.value ? _errors[field] : null;
  }

  Future<void> applyPayment() async {
    submitted.value = true;
    if (_errors.isNotEmpty) {
      Get.snackbar(
        'Revisa el pago',
        _errors.values.join(' · '),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      title: 'Aplicar pago',
      message:
          '¿Aplicar ${Formatters.currency2(amount.value)} '
          '(${method.value.label.toLowerCase()}) al préstamo de '
          '${client.value!.name}?',
      confirmLabel: 'Aplicar',
      icon: LucideIcons.banknote,
    );
    if (!confirmed) return;

    isSaving.value = true;
    try {
      final payment = await _loans.applyPayment(
        loan: loan.value!,
        amount: amount.value,
        method: method.value,
      );
      Get.offNamed(Routes.paymentReceipt, arguments: payment.id);
      // Impresión automática (Ajustes → Impresora): sin bloquear al cobrador.
      final printer = Get.find<PrinterService>();
      if (Get.find<SettingsService>().autoPrint.value && printer.isReady) {
        DocumentActions.print(ReceiptDoc(payment: payment), quiet: true);
      }
    } on AuthFailure catch (e) {
      Get.snackbar(
        'No se pudo aplicar el pago',
        e.message,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSaving.value = false;
    }
  }
}
