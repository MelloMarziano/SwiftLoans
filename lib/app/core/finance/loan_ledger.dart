import '../../data/models/client.dart';
import '../../data/models/loan.dart';

/// Estado de un préstamo a una fecha.
class LoanSnapshot {
  const LoanSnapshot({
    required this.overdueCount,
    required this.lateFeeDue,
    required this.dueToday,
    required this.amountToBeCurrent,
    required this.balance,
    required this.nextInstallment,
  });

  /// Cuotas vencidas sin pagar completas.
  final int overdueCount;

  /// Mora pendiente de todas las cuotas vencidas.
  final double lateFeeDue;

  /// Lo pendiente de la cuota que vence hoy.
  final double dueToday;

  /// Todo lo vencido hasta hoy (incluye mora y la cuota de hoy).
  final double amountToBeCurrent;

  /// Todo lo que falta para saldar el préstamo (incluye mora).
  final double balance;

  /// Primera cuota sin pagar (null si el préstamo está saldado).
  final LoanInstallment? nextInstallment;
}

class PaymentAllocation {
  const PaymentAllocation(this.items);

  /// Reconstruye el reparto guardado en un pago.
  factory PaymentAllocation.of(Payment payment) =>
      PaymentAllocation(payment.allocations);

  final List<InstallmentAllocation> items;

  double get lateFee => _sum((i) => i.lateFee);
  double get interest => _sum((i) => i.interest);
  double get capital => _sum((i) => i.capital);
  double get total => lateFee + interest + capital;

  List<int> get completed => [
    for (final i in items)
      if (i.completes) i.number,
  ];

  double _sum(double Function(InstallmentAllocation) f) =>
      _round(items.fold(0, (s, i) => s + f(i)));
}

/// Reglas de cobro:
/// - Mora: cargo único de [Loan.lateFeeRate]% sobre la cuota, por cada cuota
///   vencida (fecha anterior a hoy) que no esté saldada.
/// - Un pago se aplica de la cuota más vieja a la más nueva y, dentro de cada
///   cuota, primero a la mora, luego al interés y luego al capital. Lo que
///   sobra adelanta cuotas futuras.
abstract class LoanLedger {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isOverdue(LoanInstallment i, DateTime asOf) =>
      !i.isPaid && _day(i.dueDate).isBefore(_day(asOf));

  /// Mora pendiente de una cuota a la fecha [asOf].
  static double lateFeeFor(Loan loan, LoanInstallment i, DateTime asOf) {
    if (!isOverdue(i, asOf) || loan.lateFeeRate <= 0) return 0;
    final fee = _round(i.payment * loan.lateFeeRate / 100);
    return _round((fee - i.paidLateFee).clamp(0, double.infinity));
  }

  static LoanSnapshot snapshot(Loan loan, DateTime asOf) {
    final today = _day(asOf);
    var overdueCount = 0;
    var lateFee = 0.0;
    var dueToday = 0.0;
    var toBeCurrent = 0.0;
    var balance = 0.0;

    for (final i in loan.installments) {
      final fee = lateFeeFor(loan, i, asOf);
      final due = _day(i.dueDate);
      balance += i.pending + fee;
      lateFee += fee;
      if (isOverdue(i, asOf)) overdueCount++;
      if (due == today) dueToday += i.pending;
      if (!due.isAfter(today)) toBeCurrent += i.pending + fee;
    }

    return LoanSnapshot(
      overdueCount: overdueCount,
      lateFeeDue: _round(lateFee),
      dueToday: _round(dueToday),
      amountToBeCurrent: _round(toBeCurrent),
      balance: _round(balance),
      nextInstallment: loan.installments.where((i) => !i.isPaid).firstOrNull,
    );
  }

  /// Estado que se muestra en el cliente (chip de la lista).
  static ClientLoanStatus statusOf(Loan loan, DateTime asOf) {
    final s = snapshot(loan, asOf);
    if (s.balance == 0) return ClientLoanStatus.none;
    if (s.overdueCount > 0) return ClientLoanStatus.overdue;
    if (s.dueToday > 0) return ClientLoanStatus.toCollect;
    return ClientLoanStatus.upToDate;
  }

  /// Reparte [amount] sin modificar el préstamo (sirve para la vista previa).
  static PaymentAllocation allocate(Loan loan, double amount, DateTime asOf) {
    var left = _round(amount);
    final items = <InstallmentAllocation>[];

    for (final i in loan.installments) {
      if (left <= 0) break;
      final fee = lateFeeFor(loan, i, asOf);
      if (i.isPaid && fee == 0) continue;

      double take(double pending) {
        final value = _round(pending < left ? pending : left);
        left = _round(left - value);
        return value;
      }

      final toFee = take(fee);
      final toInterest = take(i.pendingInterest);
      final toCapital = take(i.pendingCapital);

      items.add(
        InstallmentAllocation(
          number: i.number,
          lateFee: toFee,
          interest: toInterest,
          capital: toCapital,
          completes:
              _round(i.pendingInterest - toInterest) == 0 &&
              _round(i.pendingCapital - toCapital) == 0,
        ),
      );
    }

    return PaymentAllocation(items);
  }

  /// Devuelve el préstamo con la [allocation] aplicada.
  static Loan apply(Loan loan, PaymentAllocation allocation) {
    final byNumber = {for (final a in allocation.items) a.number: a};

    return loan.withInstallments([
      for (final i in loan.installments)
        if (byNumber[i.number] case final a?)
          i.copyWith(
            paidLateFee: _round(i.paidLateFee + a.lateFee),
            paidInterest: _round(i.paidInterest + a.interest),
            paidCapital: _round(i.paidCapital + a.capital),
          )
        else
          i,
    ]);
  }

  /// Redondeo a centavos que usa el cálculo.
  static double round(double v) => _round(v);
}

double _round(double value) => (value * 100).roundToDouble() / 100;
