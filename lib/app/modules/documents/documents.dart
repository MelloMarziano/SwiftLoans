import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/finance/loan_ledger.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_user.dart';
import '../../data/models/cash_closing.dart';
import '../../data/models/client.dart';
import '../../data/models/company.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../movements/movements_controller.dart';
import '../reports/reports_controller.dart';
import 'doc_frame.dart';

final _date = DateFormat('dd/MM/yyyy');
final _dateTime = DateFormat('dd/MM/yyyy h:mm a');
String _money(num v) => Formatters.currency2(v);

/// Recibo de un pago.
class ReceiptDoc extends StatelessWidget {
  const ReceiptDoc({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final client = Get.find<ClientRepository>().byId(p.clientId);

    return DocFrame(
      title: 'Recibo de pago',
      subtitle: p.id,
      footer: Get.find<SettingsService>().receiptFooter.value,
      children: [
        DocAmount(label: 'Total pagado', value: _money(p.amount)),
        DocRow('Fecha', _dateTime.format(p.date)),
        DocRow('Cliente', client?.name ?? 'ID ${p.clientId}'),
        DocRow('ID cliente', p.clientId),
        DocRow('Préstamo', p.loanId),
        DocRow('Método', p.method.label),
        if (p.collector.isNotEmpty) DocRow('Cobrador', p.collector),
        const DocDivider(),
        DocRow('Mora', _money(p.lateFee)),
        DocRow('Interés', _money(p.interest)),
        DocRow('Capital', _money(p.capital)),
        const DocDivider(),
        DocRow(
          'Cuotas saldadas',
          p.installmentsCompleted.isEmpty
              ? 'Abono parcial'
              : p.installmentsCompleted.map((n) => '#$n').join(', '),
        ),
        DocRow('Saldo pendiente', _money(p.balanceAfter), bold: true),
      ],
    );
  }
}

/// Estado de cuenta de un préstamo: datos, saldo, cuotas y pagos.
class LoanStatementDoc extends StatelessWidget {
  const LoanStatementDoc({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context) {
    final loans = Get.find<LoanRepository>();
    final loan = loans.loanById(loanId);
    if (loan == null) {
      return const DocFrame(title: 'Estado de cuenta', children: []);
    }
    final now = loans.today;
    final s = LoanLedger.snapshot(loan, now);
    final client = Get.find<ClientRepository>().byId(loan.clientId);
    final payments = loans.paymentsOfLoan(loan.id);
    final paidCount = loan.installments.where((i) => i.isPaid).length;
    final c = DocColors.of(context);

    return DocFrame(
      title: 'Estado de cuenta',
      subtitle: 'Préstamo ${loan.id} · al ${_date.format(now)}',
      children: [
        DocRow('Cliente', client?.name ?? 'ID ${loan.clientId}'),
        if (client?.document != null) DocRow('Cédula', client!.document!),
        DocRow('Monto prestado', _money(loan.amount)),
        DocRow(
          'Cuotas',
          '$paidCount de ${loan.installments.length} '
              '${loan.frequency.installmentsAdjective}',
        ),
        DocRow('Total a pagar', _money(loan.totalDue)),
        DocAmount(
          label: 'Saldo pendiente',
          value: _money(s.balance),
          color: s.overdueCount > 0 ? c.negative : null,
        ),
        if (s.overdueCount > 0) ...[
          DocRow(
            'Cuotas vencidas',
            '${s.overdueCount} · mora ${_money(s.lateFeeDue)}',
            bold: true,
          ),
          DocRow(
            'Para ponerse al día',
            _money(s.amountToBeCurrent),
            bold: true,
          ),
        ] else if (s.nextInstallment != null)
          DocRow(
            'Próxima cuota',
            '${_date.format(s.nextInstallment!.dueDate)} · '
                '${_money(s.nextInstallment!.pending)}',
            bold: true,
          ),
        const DocDivider(),
        const DocSection('Cuotas pendientes'),
        for (final i in loan.installments.where((i) => !i.isPaid).take(12))
          DocRow(
            '#${i.number}  ${_date.format(i.dueDate)}',
            '${_money(i.pending)}'
                '${LoanLedger.isOverdue(i, now) ? '  VENCIDA' : ''}',
          ),
        if (loan.installments.where((i) => !i.isPaid).length > 12)
          DocRow(
            '…',
            '${loan.installments.where((i) => !i.isPaid).length - 12} más',
          ),
        if (payments.isNotEmpty) ...[
          const DocDivider(),
          const DocSection('Últimos pagos'),
          for (final p in payments.take(6))
            DocRow('${_date.format(p.date)}  ${p.id}', _money(p.amount)),
        ],
      ],
    );
  }
}

/// Ficha del cliente con su préstamo activo.
class ClientDoc extends StatelessWidget {
  const ClientDoc({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final loans = Get.find<LoanRepository>();
    final c = client;
    final active = loans.activeLoansOf(c.id);
    final payments = loans.paymentsOf(c.id);

    return DocFrame(
      title: 'Ficha del cliente',
      subtitle: 'ID ${c.id}',
      children: [
        DocRow('Nombre', c.name, bold: true),
        if (c.alias != null) DocRow('Apodo', c.alias!),
        if (c.document != null) DocRow('Cédula', c.document!),
        if (c.phone != null) DocRow('Teléfono', c.phone!),
        if (c.address != null) DocRow('Dirección', c.address!),
        if (c.sector != null) DocRow('Sector', c.sector!),
        DocRow('Ruta', c.route),
        DocRow(
          'Estado',
          '${c.isActive ? 'Activo' : 'Inactivo'} · ${c.loanStatus.label}',
        ),
        DocAmount(label: 'Saldo total', value: _money(c.balance)),
        for (final loan in active) ...[
          const DocDivider(),
          DocSection('Préstamo ${loan.id}'),
          () {
            final s = LoanLedger.snapshot(loan, loans.today);
            return Column(
              children: [
                DocRow('Monto', _money(loan.amount)),
                DocRow('Saldo', _money(s.balance), bold: true),
                DocRow(
                  'Atraso',
                  s.overdueCount == 0
                      ? 'Al día'
                      : '${s.overdueCount} cuotas · mora ${_money(s.lateFeeDue)}',
                ),
              ],
            );
          }(),
        ],
        if (payments.isNotEmpty) ...[
          const DocDivider(),
          const DocSection('Últimos pagos'),
          for (final p in payments.take(5))
            DocRow('${_date.format(p.date)}  ${p.id}', _money(p.amount)),
        ],
      ],
    );
  }
}

/// Resumen de movimientos del periodo (sirve de cierre del día).
class MovementsDoc extends StatelessWidget {
  const MovementsDoc({super.key, required this.controller, this.maxItems = 40});

  final MovementsController controller;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final m = controller;
    final t = m.totals;
    final items = m.visible.take(maxItems).toList();
    final time = DateFormat('dd/MM h:mm a');

    return DocFrame(
      title: 'Movimientos',
      subtitle: m.period.value.describe(m.today, m.customRange.value),
      children: [
        if (m.onlyMine)
          DocRow('Usuario', Get.find<AuthService>().user.value?.name ?? ''),
        DocRow('Entradas (${t.incomeCount} cobros)', _money(t.income)),
        DocRow('  Efectivo', _money(t.cash)),
        DocRow('  Transferencia', _money(t.transfer)),
        DocRow(
          'Préstamos (${t.loanCount})',
          '-${_money(t.outcome - t.expenses)}',
        ),
        DocRow('Gastos (${t.expenseCount})', '-${_money(t.expenses)}'),
        DocAmount(
          label: 'Neto del periodo',
          value: '${t.net < 0 ? '-' : ''}${_money(t.net.abs())}',
        ),
        if (items.isNotEmpty) ...[
          const DocSection('Detalle'),
          for (final x in items)
            DocRow(
              '${time.format(x.date)} ${x.clientName}',
              '${x.isIncome ? '+' : '-'}${_money(x.amount)}',
            ),
          if (m.visible.length > items.length)
            DocRow('…', '${m.visible.length - items.length} movimientos más'),
        ],
      ],
    );
  }
}

/// Resumen del reporte del periodo.
class ReportDoc extends StatelessWidget {
  const ReportDoc({super.key, required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller;
    final (expected, paid) = r.collectionEffectiveness;
    final people = r.onlyMine ? const <PersonRow>[] : r.byPerson;

    return DocFrame(
      title: 'Reporte',
      subtitle: r.period.value.describe(r.today, r.customRange.value),
      children: [
        DocRow('Cobrado (${r.periodPayments.length})', _money(r.collected)),
        DocRow('  Capital', _money(r.collectedCapital)),
        DocRow('  Interés', _money(r.collectedInterest)),
        DocRow('  Mora', _money(r.collectedLateFee)),
        DocRow('Prestado (${r.periodLoans.length})', _money(r.disbursed)),
        DocRow('Gastos (${r.periodExpenses.length})', _money(r.spent)),
        DocAmount(
          label: 'Ganancia (interés + mora − gastos)',
          value: '${r.profit < 0 ? '-' : ''}${_money(r.profit.abs())}',
        ),
        DocRow(
          'Efectividad de cobro',
          expected == 0 ? '—' : Formatters.percent(paid / expected),
          bold: true,
        ),
        const DocDivider(),
        const DocSection('Cartera a hoy'),
        DocRow('Total', _money(r.portfolio), bold: true),
        DocRow('En atraso', Formatters.percent(r.atRiskRatio)),
        for (final a in r.aging)
          DocRow('${a.bucket.label} (${a.count})', _money(a.balance)),
        if (people.isNotEmpty) ...[
          const DocDivider(),
          const DocSection('Por usuario'),
          for (final p in people)
            DocRow('${p.name} (${p.payments})', _money(p.collected)),
        ],
      ],
    );
  }
}

/// Resumen de una empresa (solo ROOT).
class CompanyDoc extends StatelessWidget {
  const CompanyDoc({
    super.key,
    required this.company,
    required this.users,
    this.stats,
  });

  final Company company;
  final List<AppUser> users;
  final CompanyStats? stats;

  @override
  Widget build(BuildContext context) {
    final c = company;
    return DocFrame(
      title: 'Empresa',
      subtitle: c.name,
      children: [
        DocRow('Dueño', c.ownerName),
        if (c.rnc != null) DocRow('RNC', c.rnc!),
        if (c.phone != null) DocRow('Teléfono', c.phone!),
        DocRow('Estado', c.active ? 'Activa' : 'Suspendida', bold: true),
        DocRow('Usuarios', '${c.userCount} de ${c.maxUsers}'),
        if (stats != null) ...[
          DocRow('Clientes', '${stats!.clients}'),
          DocAmount(label: 'Cartera', value: _money(stats!.portfolio)),
        ],
        if (users.isNotEmpty) ...[
          const DocSection('Usuarios'),
          for (final u in users)
            DocRow(
              '${u.name} (${u.username})',
              '${u.role.label}${u.active ? '' : ' · inactivo'}',
            ),
        ],
      ],
    );
  }
}

/// Cuadre de caja de un usuario.
class CashClosingDoc extends StatelessWidget {
  const CashClosingDoc({super.key, required this.closing});

  final CashClosing closing;

  @override
  Widget build(BuildContext context) {
    final x = closing;
    final balance = ClosingBalance.of(x.difference);
    final c = DocColors.of(context);
    final counted = x.denominations.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return DocFrame(
      title: 'Cuadre de caja',
      subtitle: '${_date.format(x.day)} · ${x.byName}',
      children: [
        DocRow('Fondo inicial', _money(x.openingCash)),
        DocRow('+ Cobros en efectivo (${x.paymentsCount})', _money(x.cashIn)),
        DocRow('− Préstamos entregados', _money(x.cashLoans)),
        DocRow('− Gastos en efectivo', _money(x.cashExpenses)),
        const DocDivider(),
        DocRow('Efectivo esperado', _money(x.expected), bold: true),
        DocRow('Efectivo contado', _money(x.counted), bold: true),
        DocAmount(
          label: balance.label,
          value: balance == ClosingBalance.even
              ? _money(0)
              : '${x.difference > 0 ? '+' : '-'}${_money(x.difference.abs())}',
          color: switch (balance) {
            ClosingBalance.even => c.positive,
            ClosingBalance.over => const Color(0xFFB7791F),
            ClosingBalance.short => c.negative,
          },
        ),
        if (x.transferIn > 0)
          DocRow('Cobros por transferencia', _money(x.transferIn)),
        if (counted.isNotEmpty) ...[
          const DocSection('Conteo'),
          for (final e in counted)
            DocRow(
              '${e.value} × ${Formatters.currency(e.key)}',
              _money(e.key * e.value),
            ),
        ],
        if (x.notes != null) ...[const DocSection('Notas'), Text(x.notes!)],
        const DocDivider(),
        DocRow(
          'Estado',
          x.status == ClosingStatus.approved && x.reviewedBy != null
              ? 'Revisado por ${x.reviewedBy}'
              : x.status.label,
          bold: true,
        ),
        DocRow('Cerrado', _dateTime.format(x.createdAt)),
      ],
    );
  }
}
