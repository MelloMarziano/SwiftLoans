import '../../data/models/expense.dart';
import '../../data/models/loan.dart';

/// Lo que movió un usuario en un día, para el cuadre de caja. Los préstamos
/// se entregan en efectivo; los cobros y gastos por transferencia no tocan
/// la caja.
class CashSummary {
  CashSummary._();

  factory CashSummary.of({
    required DateTime day,
    required String uid,
    required String name,
    required Iterable<Payment> payments,
    required Iterable<Loan> loans,
    required Iterable<Expense> expenses,
  }) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    bool inDay(DateTime d) => !d.isBefore(from) && d.isBefore(to);
    // Pagos viejos sin collectorUid: se reconoce al cobrador por el nombre.
    bool mine(String? byUid, String byName) =>
        byUid == null ? byName == name : byUid == uid;

    final s = CashSummary._();
    for (final p in payments) {
      if (!inDay(p.date) || !mine(p.collectorUid, p.collector)) continue;
      s.paymentsCount++;
      if (p.method == PaymentMethod.transfer) {
        s.transferIn += p.amount;
      } else {
        s.cashPayments++;
        s.cashIn += p.amount;
      }
    }
    for (final l in loans) {
      if (!inDay(l.createdAt ?? l.startDate) || l.createdByUid != uid) continue;
      s.loansCount++;
      s.cashLoans += l.amount;
    }
    for (final e in expenses) {
      if (!inDay(e.date) || e.byUid != uid) continue;
      s.expensesCount++;
      if (e.method == PaymentMethod.cash) s.cashExpenses += e.amount;
    }
    return s;
  }

  int paymentsCount = 0;
  int cashPayments = 0;
  int loansCount = 0;
  int expensesCount = 0;
  double cashIn = 0;
  double transferIn = 0;
  double cashLoans = 0;
  double cashExpenses = 0;

  bool get isEmpty => paymentsCount + loansCount + expensesCount == 0;

  /// Efectivo esperado sin contar el fondo inicial.
  double get netCash => cashIn - cashLoans - cashExpenses;
}
