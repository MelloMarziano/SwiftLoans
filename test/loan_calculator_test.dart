import 'package:flutter_test/flutter_test.dart';
import 'package:swiftloans/app/core/finance/loan_calculator.dart';
import 'package:swiftloans/app/data/models/loan_terms.dart';

void main() {
  final start = DateTime(2026, 11, 15);

  LoanQuote quote({
    double principal = 10000,
    double rate = 20,
    int n = 4,
    PaymentFrequency frequency = PaymentFrequency.monthly,
    LoanType type = LoanType.interestAndCapital,
    double closingCost = 0,
    bool finance = false,
  }) => LoanCalculator.quote(
    principal: principal,
    monthlyRatePercent: rate,
    installments: n,
    frequency: frequency,
    type: type,
    startDate: start,
    closingCost: closingCost,
    financeClosingCost: finance,
  );

  test('interés y capital: cuota = capital/n + interés fijo', () {
    final q = quote();
    expect(q.payment, 2500 + 2000);
    expect(q.totalInterest, 8000);
    expect(q.schedule.last.balance, 0);
  });

  test('tasa diaria = mensual / 30', () {
    final q = quote(frequency: PaymentFrequency.daily, n: 30);
    expect(q.periodRate, closeTo(0.2 / 30, 1e-12));
    expect(q.schedule.first.dueDate, DateTime(2026, 11, 16));
    expect(q.schedule.last.dueDate, DateTime(2026, 12, 15));
  });

  test('solo interés: el capital se paga en la última cuota', () {
    final q = quote(type: LoanType.interestOnly);
    expect(q.schedule.first.payment, 2000);
    expect(q.schedule.last.payment, 12000);
  });

  test('amortizado: cuota fija y saldo final en cero', () {
    final q = quote(type: LoanType.amortized, rate: 5, n: 12);
    final payments = q.schedule.map((i) => i.payment).toList();
    expect(payments.first, closeTo(1128.25, 0.01));
    expect(payments.last, closeTo(payments.first, 0.1));
    expect(q.schedule.last.balance, 0);
  });

  test('el capital cuadra exacto aunque no divida parejo', () {
    final q = quote(principal: 1000, n: 3);
    final capital = q.schedule.fold<double>(0, (s, i) => s + i.capital);
    expect(capital, closeTo(1000, 1e-9));
  });

  test('interés total exacto aunque la cuota tenga centavos', () {
    final q = quote(frequency: PaymentFrequency.daily, n: 30);
    expect(q.totalInterest, closeTo(2000, 1e-9));
    expect(q.totalPayment, closeTo(12000, 1e-9));
  });

  test('gasto de cierre financiado se suma al capital', () {
    expect(quote(closingCost: 500, finance: true).financedAmount, 10500);
    expect(quote(closingCost: 500).financedAmount, 10000);
  });

  test('cuota mensual respeta fin de mes', () {
    final q = LoanCalculator.quote(
      principal: 1000,
      monthlyRatePercent: 10,
      installments: 2,
      frequency: PaymentFrequency.monthly,
      type: LoanType.interestAndCapital,
      startDate: DateTime(2026, 1, 31),
    );
    expect(q.schedule.first.dueDate, DateTime(2026, 2, 28));
  });

  test('sin monto no genera cuotas', () {
    expect(quote(principal: 0).schedule, isEmpty);
  });
}
