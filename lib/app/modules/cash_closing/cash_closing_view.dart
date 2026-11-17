import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/auth_backend.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/form/form_fields.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../core/widgets/text_input_dialog.dart';
import '../../core/widgets/motion.dart';
import '../../data/models/cash_closing.dart';
import '../documents/document_actions.dart';
import '../documents/documents.dart';
import '../root/root_controller.dart';
import '../root/widgets/app_shell.dart';
import 'cash_closing_controller.dart';

const _overColor = Color(0xFFB7791F);
const _overSoft = Color(0xFFFBF0DC);

(Color, Color, IconData) _balanceStyle(ClosingBalance b) => switch (b) {
  ClosingBalance.even => (
    AppColors.success,
    AppColors.successSoft,
    LucideIcons.circleCheck,
  ),
  ClosingBalance.over => (_overColor, _overSoft, LucideIcons.circlePlus),
  ClosingBalance.short => (
    AppColors.danger,
    AppColors.dangerSoft,
    LucideIcons.circleMinus,
  ),
};

void _showClosing(CashClosing closing, {Widget? extraAction}) =>
    DocumentSheet.show(
      title: 'Cuadre de caja',
      document: () => CashClosingDoc(closing: closing),
      fileName: closing.id.toLowerCase(),
      shareText:
          'Cuadre ${DateFormat('dd/MM/yyyy').format(closing.day)} · '
          '${closing.byName}',
      extraAction: extraAction,
    );

/// Cuadre de caja del día: lo esperado contra lo contado. Dueño y
/// administrador además ven y revisan los cuadres del equipo.
class CashClosingView extends GetView<CashClosingController> {
  const CashClosingView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Cuadre',
      showBack: true,
      activeTab: RootController.none,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = context.isCompact;
          final side = math.max(
            compact ? 14.0 : 32.0,
            (constraints.maxWidth - 760) / 2,
          );
          final gap = context.sized(14.0, 18.0);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(side, gap, side, compact ? 120 : 32),
            child: Obx(() {
              controller.watch();
              final team =
                  controller.canReview &&
                  controller.tab.value == ClosingTab.team;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DayBar(),
                  if (controller.canReview) ...[
                    SizedBox(height: gap),
                    const _Tabs(),
                  ],
                  SizedBox(height: gap),
                  if (team)
                    const _TeamList()
                  else if (controller.myClosing case final closing?)
                    _ClosedView(closing: closing).entrance()
                  else
                    const _OpenForm().entrance(),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _DayBar extends GetView<CashClosingController> {
  const _DayBar();

  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final d = controller.day.value;
    final today = controller.today;
    final label = d == today
        ? 'Hoy'
        : d == today.subtract(const Duration(days: 1))
        ? 'Ayer'
        : _weekdays[d.weekday - 1];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Día anterior',
            onPressed: controller.previousDay,
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: d,
                  firstDate: DateTime(today.year - 1),
                  lastDate: today,
                  helpText: 'Día del cuadre',
                );
                if (picked != null) controller.changeDay(picked);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(d),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Día siguiente',
            onPressed: controller.isToday ? null : controller.nextDay,
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends GetView<CashClosingController> {
  const _Tabs();

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build();
  });

  Widget _build() {
    final pending = controller.pendingReviewCount;
    return SegmentedButton<ClosingTab>(
      segments: [
        const ButtonSegment(
          value: ClosingTab.mine,
          icon: Icon(LucideIcons.wallet, size: 18),
          label: Text('Mi cuadre'),
        ),
        ButtonSegment(
          value: ClosingTab.team,
          icon: const Icon(LucideIcons.users, size: 18),
          label: Text(pending == 0 ? 'Equipo' : 'Equipo ($pending)'),
        ),
      ],
      selected: {controller.tab.value},
      onSelectionChanged: (s) => controller.tab.value = s.first,
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mi cuadre (abierto)
// ---------------------------------------------------------------------------

class _OpenForm extends GetView<CashClosingController> {
  const _OpenForm();

  @override
  Widget build(BuildContext context) {
    final gap = context.sized(12.0, 16.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ExpectedCard(),
        SizedBox(height: gap),
        const _CountCard(),
        SizedBox(height: gap),
        const _DifferenceCard(),
        SizedBox(height: gap),
        TextFieldBox(
          icon: LucideIcons.stickyNote,
          label: 'Notas (opcional)',
          hint: 'Ej. faltan 100 de un vuelto',
          controller: controller.notesController,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
        ),
        SizedBox(height: gap + 4),
        Obx(
          () => FilledButton.icon(
            onPressed: controller.isSaving.value
                ? null
                : () async {
                    final closing = await controller.close();
                    if (closing != null) _showClosing(closing);
                  },
            icon: const Icon(LucideIcons.clipboardCheck, size: 20),
            label: const Text('Cerrar cuadre'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size.fromHeight(context.sized(52, 56)),
              shape: const StadiumBorder(),
              textStyle: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: context.sized(15, 16),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpectedCard extends GetView<CashClosingController> {
  const _ExpectedCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.calculator,
      title: 'Efectivo esperado',
      child: Obx(() {
        controller.watch();
        final s = controller.mySummary;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FundBox(),
            const SizedBox(height: 10),
            _Line(
              '+ Cobros en efectivo (${s.cashPayments})',
              s.cashIn,
              color: AppColors.success,
            ),
            _Line(
              '− Préstamos entregados (${s.loansCount})',
              -s.cashLoans,
              color: _overColor,
            ),
            _Line(
              '− Gastos en efectivo (${s.expensesCount})',
              -s.cashExpenses,
              color: AppColors.danger,
            ),
            const Divider(height: 20, color: AppColors.border),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Debes tener',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                AnimatedNumber(
                  value: controller.expected,
                  format: Formatters.currency2,
                  style: TextStyle(
                    fontSize: context.sized(20, 22),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (s.transferIn > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Además cobraste ${Formatters.currency2(s.transferIn)} por '
                  'transferencia (no está en la caja).',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
            if (s.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'No tienes cobros, préstamos ni gastos este día.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {required this.color});

  final String label;
  final double value;
  final Color color;

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
            '${value < 0 ? '−' : ''}${Formatters.currency2(value.abs())}',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends GetView<CashClosingController> {
  const _CountCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.banknote,
      title: 'Efectivo contado',
      child: Obx(() {
        final byDenomination = controller.byDenomination.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (final (value, label) in [
                  (true, 'Por billetes'),
                  (false, 'Total'),
                ]) ...[
                  ChoiceChip(
                    label: Text(label),
                    selected: byDenomination == value,
                    onSelected: (_) => controller.byDenomination.value = value,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: byDenomination == value
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      color: byDenomination == value
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (byDenomination) ...[
              const _GroupLabel('Billetes'),
              for (final d in Denominations.bills) _DenominationRow(value: d),
              const SizedBox(height: 6),
              const _GroupLabel('Monedas'),
              for (final d in Denominations.coins) _DenominationRow(value: d),
            ] else
              TextFieldBox.money(
                icon: LucideIcons.banknote,
                label: 'Total contado',
                controller: controller.totalController,
              ),
            const Divider(height: 20, color: AppColors.border),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total contado',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                AnimatedNumber(
                  value: controller.counted,
                  format: Formatters.currency2,
                  style: TextStyle(
                    fontSize: context.sized(20, 22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Fila "RD$500  [−] 3 [+]  1,500".
class _DenominationRow extends StatefulWidget {
  const _DenominationRow({required this.value});

  final int value;

  @override
  State<_DenominationRow> createState() => _DenominationRowState();
}

class _DenominationRowState extends State<_DenominationRow> {
  final controller = Get.find<CashClosingController>();
  late final _text = TextEditingController(text: _qtyText);

  int get _qty => controller.counts[widget.value] ?? 0;
  String get _qtyText => _qty == 0 ? '' : '$_qty';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(int qty) {
    controller.setCount(widget.value, qty);
    _text.text = _qtyText;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final qty = _qty;
    // Si el conteo cambió desde fuera, refleja la cantidad en el campo.
    if ((int.tryParse(_text.text) ?? 0) != qty) _text.text = _qtyText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              Formatters.currency(widget.value),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          _StepButton(
            icon: LucideIcons.minus,
            onTap: qty == 0 ? null : () => _set(qty - 1),
          ),
          SizedBox(
            width: 54,
            child: TextField(
              controller: _text,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (v) {
                controller.setCount(widget.value, int.tryParse(v) ?? 0);
                setState(() {});
              },
              style: const TextStyle(fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          _StepButton(icon: LucideIcons.plus, onTap: () => _set(qty + 1)),
          Expanded(
            child: Text(
              qty == 0 ? '—' : Formatters.currency(widget.value * qty),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: qty == 0 ? AppColors.textSecondary : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppColors.background : AppColors.accentSoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? AppColors.textSecondary : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _DifferenceCard extends GetView<CashClosingController> {
  const _DifferenceCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.watch();
      final diff = controller.difference;
      final balance = ClosingBalance.of(diff);
      final (color, soft, icon) = _balanceStyle(balance);
      return AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.curve,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balance.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    balance == ClosingBalance.even
                        ? 'Lo contado coincide con lo esperado.'
                        : balance == ClosingBalance.over
                        ? 'Tienes más dinero del que deberías.'
                        : 'Te falta dinero. Revisa el conteo.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            AnimatedNumber(
              value: diff,
              format: (v) => v.abs() < 0.01
                  ? '0.00'
                  : '${v > 0 ? '+' : '−'}${Formatters.currency2(v.abs())}',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Pide el monto del fondo y lo asigna (dueño/administrador).
Future<void> _assignFund({
  required String uid,
  required String name,
  double? current,
}) async {
  final controller = Get.find<CashClosingController>();
  final value = await TextInputDialog.show(
    title: 'Fondo inicial de $name',
    label: 'Efectivo para cambio',
    initialValue: current == null ? '' : current.toStringAsFixed(0),
    confirmLabel: 'Asignar',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (v) {
      final n = double.tryParse(v.replaceAll(',', ''));
      return n == null || n < 0 ? 'Escribe un monto válido' : null;
    },
  );
  if (value == null) return;
  try {
    await controller.assignFund(
      uid,
      name,
      double.parse(value.replaceAll(',', '')),
    );
  } on AuthFailure catch (e) {
    Get.snackbar(
      'No se pudo asignar',
      e.message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
    );
  }
}

/// Fondo inicial asignado (solo lectura para el cobrador).
class _FundBox extends GetView<CashClosingController> {
  const _FundBox();

  static final _time = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final fund = controller.myFund;
    final me = controller.me;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fund == null ? _overSoft : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fund == null
              ? _overColor.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.piggyBank,
            color: fund == null ? _overColor : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fondo inicial',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  fund == null
                      ? 'Sin fondo asignado'
                      : Formatters.currency2(fund.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fund == null ? _overColor : null,
                  ),
                ),
                Text(
                  fund == null
                      ? (controller.canReview
                            ? 'Asígnatelo o déjalo en 0.'
                            : 'Pídeselo a tu administrador; si no, cuenta 0.')
                      : 'Asignado por ${fund.assignedBy} · '
                            '${_time.format(fund.assignedAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (controller.canReview && me != null)
            TextButton(
              onPressed: () => _assignFund(
                uid: me.uid,
                name: me.name,
                current: fund?.amount,
              ),
              child: Text(fund == null ? 'Asignar' : 'Cambiar'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mi cuadre (cerrado)
// ---------------------------------------------------------------------------

class _ClosedView extends GetView<CashClosingController> {
  const _ClosedView({required this.closing});

  final CashClosing closing;

  @override
  Widget build(BuildContext context) {
    final c = closing;
    final balance = ClosingBalance.of(c.difference);
    final (color, soft, icon) = _balanceStyle(balance);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionCard(
          icon: LucideIcons.clipboardCheck,
          title: 'Cuadre cerrado',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        balance.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      balance == ClosingBalance.even
                          ? '0.00'
                          : '${c.difference > 0 ? '+' : '−'}'
                                '${Formatters.currency2(c.difference.abs())}',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _Line(
                'Fondo inicial',
                c.openingCash,
                color: AppColors.textPrimary,
              ),
              _Line('+ Cobros en efectivo', c.cashIn, color: AppColors.success),
              _Line('− Préstamos entregados', -c.cashLoans, color: _overColor),
              _Line(
                '− Gastos en efectivo',
                -c.cashExpenses,
                color: AppColors.danger,
              ),
              const Divider(height: 18, color: AppColors.border),
              _Line('Esperado', c.expected, color: AppColors.primary),
              _Line('Contado', c.counted, color: AppColors.textPrimary),
              const SizedBox(height: 8),
              _StatusChip(closing: c),
            ],
          ),
        ),
        if (controller.changedAfterClosing) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _overSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.triangleAlert, color: _overColor, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hubo movimientos después de cerrar el cuadre. '
                    'Avísale al administrador.',
                    style: TextStyle(color: _overColor),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _showClosing(c),
          icon: const Icon(LucideIcons.share2, size: 20),
          label: const Text('Compartir o imprimir'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.closing});

  final CashClosing closing;

  @override
  Widget build(BuildContext context) {
    final approved = closing.status == ClosingStatus.approved;
    final color = approved ? AppColors.primary : _overColor;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: approved ? AppColors.accentSoft : _overSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              approved ? LucideIcons.badgeCheck : LucideIcons.clock,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              approved && closing.reviewedBy != null
                  ? 'Revisado por ${closing.reviewedBy}'
                  : closing.status.label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Equipo
// ---------------------------------------------------------------------------

class _TeamList extends GetView<CashClosingController> {
  const _TeamList();

  @override
  Widget build(BuildContext context) => Obx(() {
    controller.watch();
    return _build();
  });

  Widget _build() {
    final rows = controller.team;
    if (rows.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.users,
        title: 'Sin actividad',
        message: 'Nadie cobró, prestó ni gastó este día.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _TeamCard(key: ValueKey(rows[i].uid), row: rows[i]).entrance(i),
        ],
      ],
    );
  }
}

class _TeamCard extends GetView<CashClosingController> {
  const _TeamCard({super.key, required this.row});

  final TeamRow row;

  void _open() {
    final c = row.closing;
    if (c == null) {
      Get.snackbar(
        '${row.name} aún no cuadra',
        'Efectivo esperado sin fondo: '
            '${Formatters.currency2(row.summary.netCash)}',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    _showClosing(
      c,
      extraAction: c.status == ClosingStatus.pending
          ? OutlinedButton.icon(
              onPressed: () async {
                try {
                  await controller.approve(c);
                  Get.back();
                  Get.snackbar(
                    'Cuadre revisado',
                    c.byName,
                    snackPosition: SnackPosition.TOP,
                    margin: const EdgeInsets.all(16),
                  );
                } on AuthFailure catch (e) {
                  Get.snackbar(
                    'No se pudo marcar',
                    e.message,
                    snackPosition: SnackPosition.TOP,
                    margin: const EdgeInsets.all(16),
                  );
                }
              },
              icon: const Icon(LucideIcons.badgeCheck, size: 20),
              label: const Text('Marcar revisado'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                backgroundColor: AppColors.surface,
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = row.closing;
    final s = row.summary;
    final radius = BorderRadius.circular(18);
    final balance = c == null ? null : ClosingBalance.of(c.difference);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: InkWell(
          onTap: _open,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.avatar,
                  child: Text(
                    row.name.isEmpty ? '?' : row.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${s.paymentsCount} ${s.paymentsCount == 1 ? 'cobro' : 'cobros'} · efectivo '
                        '${Formatters.currency2(s.cashIn)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        row.fund == null
                            ? 'Sin fondo asignado'
                            : 'Fondo ${Formatters.currency2(row.fund!.amount)}',
                        style: TextStyle(
                          color: row.fund == null
                              ? _overColor
                              : AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: row.fund == null ? FontWeight.w700 : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (c == null)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const _Pill(
                              text: 'Sin cuadre',
                              color: AppColors.danger,
                              background: AppColors.dangerSoft,
                              icon: LucideIcons.clockAlert,
                            ),
                            ActionChip(
                              avatar: const Icon(
                                LucideIcons.piggyBank,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                row.fund == null
                                    ? 'Asignar fondo'
                                    : 'Cambiar fondo',
                              ),
                              onPressed: () => _assignFund(
                                uid: row.uid,
                                name: row.name,
                                current: row.fund?.amount,
                              ),
                              backgroundColor: AppColors.accentSoft,
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                              visualDensity: VisualDensity.compact,
                              labelStyle: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        )
                      else
                        _StatusChip(closing: c),
                    ],
                  ),
                ),
                if (c != null && balance != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        balance.label,
                        style: TextStyle(
                          color: _balanceStyle(balance).$1,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        balance == ClosingBalance.even
                            ? Formatters.currency2(c.counted)
                            : '${c.difference > 0 ? '+' : '−'}'
                                  '${Formatters.currency2(c.difference.abs())}',
                        style: TextStyle(
                          color: _balanceStyle(balance).$1,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String text;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
