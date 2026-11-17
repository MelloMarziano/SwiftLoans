import 'package:flutter_test/flutter_test.dart';
import 'package:swiftloans/app/core/finance/loan_calculator.dart';
import 'package:swiftloans/app/core/finance/loan_ledger.dart';
import 'package:swiftloans/app/data/models/client.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/models/loan_terms.dart';

void main() {
  // 10,000 al 20% diario en 30 cuotas: cuota 400 (333.33 capital + 66.67 interés).
  final start = DateTime(2026, 11, 1);
  final today = DateTime(2026, 11, 5); // vencen las cuotas 1-3, la 4 es hoy

  Loan loan({double lateFeeRate = 5}) {
    final quote = LoanCalculator.quote(
      principal: 10000,
      monthlyRatePercent: 20,
      installments: 30,
      frequency: PaymentFrequency.daily,
      type: LoanType.interestAndCapital,
      startDate: start,
    );
    return Loan(
      id: 'P-1',
      clientId: '1',
      amount: 10000,
      frequency: PaymentFrequency.daily,
      type: LoanType.interestAndCapital,
      monthlyRate: 20,
      lateFeeRate: lateFeeRate,
      startDate: start,
      installments: quote.schedule.map(LoanInstallment.fromSchedule).toList(),
    );
  }

  test('snapshot: vencidas, mora y cuota de hoy', () {
    final s = LoanLedger.snapshot(loan(), today);
    expect(s.overdueCount, 3);
    expect(s.lateFeeDue, 60); // 5% de 400 x 3
    expect(s.dueToday, 400);
    expect(s.amountToBeCurrent, 400 * 4 + 60);
    expect(LoanLedger.statusOf(loan(), today), ClientLoanStatus.overdue);
  });

  test('aplica mora, luego interés, luego capital, de la cuota más vieja', () {
    final a = LoanLedger.allocate(loan(), 100, today);
    final first = a.items.first;
    expect(first.number, 1);
    expect(first.lateFee, 20);
    expect(first.interest, 66.67);
    expect(first.capital, closeTo(13.33, 1e-9));
    expect(first.completes, isFalse);
    expect(a.total, 100);
  });

  test('pago parcial deja la cuota abierta sin volver a cobrar mora', () {
    var l = loan();
    l = LoanLedger.apply(l, LoanLedger.allocate(l, 100, today));
    expect(LoanLedger.lateFeeFor(l, l.installments.first, today), 0);
    expect(l.installments.first.pendingCapital, closeTo(320, 1e-9));
  });

  test('ponerse al día deja el préstamo "al día"', () {
    var l = loan();
    final due = LoanLedger.snapshot(l, today).amountToBeCurrent;
    final a = LoanLedger.allocate(l, due, today);
    expect(a.completed, [1, 2, 3, 4]);
    l = LoanLedger.apply(l, a);
    expect(LoanLedger.statusOf(l, today), ClientLoanStatus.upToDate);
  });

  test('pagar el saldo total salda el préstamo', () {
    var l = loan();
    final balance = LoanLedger.snapshot(l, today).balance;
    l = LoanLedger.apply(l, LoanLedger.allocate(l, balance, today));
    expect(l.isPaidOff, isTrue);
    expect(LoanLedger.statusOf(l, today), ClientLoanStatus.none);
  });

  test('sin vencidas y con cuota hoy queda "por cobrar"', () {
    var l = loan(lateFeeRate: 0);
    l = LoanLedger.apply(l, LoanLedger.allocate(l, 1200, today));
    expect(LoanLedger.statusOf(l, today), ClientLoanStatus.toCollect);
  });
}
