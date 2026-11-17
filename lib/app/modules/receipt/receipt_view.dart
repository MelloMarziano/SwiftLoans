import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/printer_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/motion.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../documents/document_actions.dart';
import '../documents/documents.dart';
import '../root/widgets/app_shell.dart';

/// Recibo de un pago. Recibe el número de recibo como argumento.
class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key});

  static final _date = DateFormat('dd/MM/yyyy  h:mm a', 'es');

  @override
  Widget build(BuildContext context) {
    final id = Get.arguments as String?;
    final payment = id == null
        ? null
        : Get.find<LoanRepository>().paymentById(id);

    return AppShell(
      title: 'Recibo de pago',
      showBack: true,
      body: payment == null
          ? const EmptyState(
              icon: LucideIcons.receiptText,
              title: 'Recibo no encontrado',
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.sized(14, 32),
                context.sized(14, 24),
                context.sized(14, 32),
                context.isCompact ? 120 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReceiptCard(payment: payment).entrance(),
                      const SizedBox(height: 16),
                      _ShareAndPrint(payment: payment),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: Get.back,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: const Text('Listo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final client = Get.find<ClientRepository>().byId(payment.clientId);
    final settings = Get.find<SettingsService>();
    final p = payment;

    Widget row(String label, String value, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: color ?? AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandWordmark(height: 40)),
          const SizedBox(height: 8),
          const _BusinessInfo(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      size: 18,
                      color: AppColors.success,
                    ).animate().scale(
                      begin: Offset(0.2, 0.2),
                      duration: Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Pago aplicado',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedNumber(
                  value: p.amount,
                  format: Formatters.currency2,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          row('Recibo', p.id, bold: true),
          row('Fecha', ReceiptView._date.format(p.date)),
          row('Cliente', client?.name ?? 'ID ${p.clientId}'),
          row('ID cliente', p.clientId),
          row('Préstamo', p.loanId),
          row('Método', p.method.label),
          row('Cobrador', p.collector),
          const _Dashed(),
          row('Mora', Formatters.currency2(p.lateFee)),
          row('Interés', Formatters.currency2(p.interest)),
          row('Capital', Formatters.currency2(p.capital)),
          row('Total pagado', Formatters.currency2(p.amount), bold: true),
          const _Dashed(),
          row(
            'Cuotas saldadas',
            p.installmentsCompleted.isEmpty
                ? 'Abono parcial'
                : p.installmentsCompleted.map((n) => '#$n').join(', '),
          ),
          row(
            'Saldo pendiente',
            Formatters.currency2(p.balanceAfter),
            bold: true,
            color: AppColors.primary,
          ),
          if (settings.receiptFooter.value.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              settings.receiptFooter.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Nombre, RNC, teléfono y dirección configurados en Ajustes.
class _BusinessInfo extends StatelessWidget {
  const _BusinessInfo();

  @override
  Widget build(BuildContext context) {
    final s = Get.find<SettingsService>();
    final lines = [
      if (s.businessRnc.value.isNotEmpty) 'RNC: ${s.businessRnc.value}',
      if (s.businessPhone.value.isNotEmpty) 'Tel.: ${s.businessPhone.value}',
      if (s.businessAddress.value.isNotEmpty) s.businessAddress.value,
    ];

    return Column(
      children: [
        Text(
          s.businessName.value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        for (final line in lines)
          Text(
            line,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 8).floor();
          return Row(
            children: List.generate(
              count,
              (_) => Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: AppColors.border,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compartir el recibo como imagen (WhatsApp...) o imprimirlo.
class _ShareAndPrint extends StatelessWidget {
  const _ShareAndPrint({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final printer = Get.find<PrinterService>();
    final client = Get.find<ClientRepository>().byId(payment.clientId);
    ButtonStyle style(Color fg, Color border) => OutlinedButton.styleFrom(
      foregroundColor: fg,
      side: BorderSide(color: border),
      minimumSize: const Size.fromHeight(50),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
      ),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => DocumentActions.share(
              ReceiptDoc(payment: payment),
              fileName: 'recibo-${payment.id}',
              text:
                  'Recibo ${payment.id} · ${client?.name ?? ''} · '
                  '${Formatters.currency2(payment.amount)}',
            ),
            icon: const Icon(LucideIcons.share2, size: 20),
            label: const Text('Compartir'),
            style: style(AppColors.success, AppColors.success),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Obx(
            () => OutlinedButton.icon(
              onPressed: printer.isPrinting.value
                  ? null
                  : () => DocumentActions.print(ReceiptDoc(payment: payment)),
              icon: const Icon(LucideIcons.printer, size: 20),
              label: Text(
                printer.isPrinting.value ? 'Imprimiendo…' : 'Imprimir',
              ),
              style: style(AppColors.primary, AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
