import 'dart:math';

import '../../core/finance/loan_calculator.dart';
import '../../core/finance/loan_ledger.dart';
import '../models/client.dart';
import '../models/loan.dart';
import '../models/loan_terms.dart';

/// Préstamos de ejemplo coherentes con el estado de cada cliente, con los
/// pagos que los dejaron así (para que Movimientos tenga historial).
abstract class MockLoans {
  static const _amounts = [5000.0, 8000.0, 10000.0, 15000.0, 20000.0, 25000.0];

  /// Cobradores de ejemplo (el primero coincide con el de los tests).
  static const collectors = [('c1', 'Pedro Cobrador'), ('c2', 'Luis Cobrador')];

  static (List<Loan>, List<Payment>) generate(
    List<Client> clients,
    DateTime today,
  ) {
    final random = Random(11);
    final day = DateTime(today.year, today.month, today.day);
    var nextId = 500;
    var receipt = 1;
    final loans = <Loan>[];
    final payments = <Payment>[];

    for (final (index, client) in clients.where((c) => c.hasLoan).indexed) {
      final elapsed = 4 + random.nextInt(16); // la cuota [elapsed] vence hoy
      final start = day.subtract(Duration(days: elapsed));
      final amount = _amounts[random.nextInt(_amounts.length)];
      final quote = LoanCalculator.quote(
        principal: amount,
        monthlyRatePercent: 20,
        installments: 30,
        frequency: PaymentFrequency.daily,
        type: LoanType.interestAndCapital,
        startDate: start,
      );

      final paid = switch (client.loanStatus) {
        ClientLoanStatus.upToDate => elapsed,
        ClientLoanStatus.toCollect => elapsed - 1,
        _ => elapsed - 2 - random.nextInt(3), // vencido
      };

      final loan = Loan(
        id: 'P-${nextId++}',
        clientId: client.id,
        amount: amount,
        frequency: PaymentFrequency.daily,
        type: LoanType.interestAndCapital,
        monthlyRate: 20,
        lateFeeRate: 5,
        startDate: start,
        createdAt: start.add(Duration(hours: 9, minutes: random.nextInt(50))),
        createdByUid: 'demo-owner',
        createdBy: 'Francisco',
        installments: quote.schedule.map(LoanInstallment.fromSchedule).toList(),
      );
      loans.add(loan);

      // Una cuota pagada el mismo día en que vence (sin mora).
      final (uid, name) = collectors[index % collectors.length];
      var state = loan;
      for (final i in quote.schedule.take(paid)) {
        final at = i.dueDate.add(
          Duration(hours: 8 + random.nextInt(9), minutes: random.nextInt(60)),
        );
        // Nunca en el futuro (las cuotas de hoy se cobraron "hace un rato").
        final date = at.isAfter(today)
            ? today.subtract(Duration(minutes: 1 + random.nextInt(30)))
            : at;
        final allocation = LoanLedger.allocate(state, i.payment, date);
        state = LoanLedger.apply(state, allocation);
        payments.add(
          Payment(
            id: 'R-${(receipt++).toString().padLeft(6, '0')}',
            loanId: loan.id,
            clientId: client.id,
            date: date,
            amount: allocation.total,
            method: random.nextInt(5) == 0
                ? PaymentMethod.transfer
                : PaymentMethod.cash,
            lateFee: allocation.lateFee,
            interest: allocation.interest,
            capital: allocation.capital,
            installmentsCompleted: allocation.completed,
            balanceAfter: LoanLedger.snapshot(state, date).balance,
            collector: name,
            collectorUid: uid,
            allocations: allocation.items,
          ),
        );
      }
    }
    return (loans, payments);
  }
}
