import 'dart:math' as math;

import '../../data/models/loan_terms.dart';

class LoanQuote {
  const LoanQuote({
    required this.financedAmount,
    required this.periodRate,
    required this.schedule,
  });

  /// Capital prestado, incluyendo el gasto de cierre si se financia.
  final double financedAmount;

  /// Tasa por periodo (fracción, no porcentaje).
  final double periodRate;
  final List<Installment> schedule;

  /// Cuota regular (la primera; en "Solo interés" la última incluye el capital).
  double get payment => schedule.isEmpty ? 0 : schedule.first.payment;

  double get totalInterest => schedule.fold(0, (sum, i) => sum + i.interest);

  double get totalPayment => financedAmount + totalInterest;
}

/// Cálculo de cuotas. Los montos se redondean a centavos y el ajuste de
/// redondeo se aplica en la última cuota, para que el capital cuadre exacto.
abstract class LoanCalculator {
  static LoanQuote quote({
    required double principal,
    required double monthlyRatePercent,
    required int installments,
    required PaymentFrequency frequency,
    required LoanType type,
    required DateTime startDate,
    double closingCost = 0,
    bool financeClosingCost = false,
  }) {
    final amount = _round(principal + (financeClosingCost ? closingCost : 0));
    final rate = monthlyRatePercent / 100 / frequency.periodsPerMonth;

    if (amount <= 0 || installments <= 0) {
      return LoanQuote(
        financedAmount: amount,
        periodRate: rate,
        schedule: const [],
      );
    }

    final schedule = <Installment>[];
    var balance = amount;
    var interestSoFar = 0.0;

    // Con interés fijo el total se calcula exacto y el redondeo de centavos
    // se absorbe en la última cuota.
    final flatInterest = _round(amount * rate);
    final flatInterestTotal = _round(amount * rate * installments);

    // Cuota fija del sistema francés (solo se usa en el tipo amortizado).
    final fixedPayment = rate == 0
        ? amount / installments
        : amount * rate / (1 - math.pow(1 + rate, -installments));

    for (var n = 1; n <= installments; n++) {
      final isLast = n == installments;

      final (capital, interest) = switch (type) {
        LoanType.interestAndCapital => (
          isLast ? balance : _round(amount / installments),
          isLast ? _round(flatInterestTotal - interestSoFar) : flatInterest,
        ),
        LoanType.interestOnly => (
          isLast ? balance : 0.0,
          isLast ? _round(flatInterestTotal - interestSoFar) : flatInterest,
        ),
        LoanType.amortized => () {
          final interest = _round(balance * rate);
          final capital = isLast ? balance : _round(fixedPayment - interest);
          return (capital, interest);
        }(),
      };

      balance = _round(balance - capital);
      interestSoFar += interest;
      schedule.add(
        Installment(
          number: n,
          dueDate: frequency.dueDate(startDate, n),
          capital: capital,
          interest: interest,
          balance: balance,
        ),
      );
    }

    return LoanQuote(
      financedAmount: amount,
      periodRate: rate,
      schedule: schedule,
    );
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}
