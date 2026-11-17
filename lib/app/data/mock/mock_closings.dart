import '../../core/finance/cash_summary.dart';
import '../models/cash_closing.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import 'mock_loans.dart';

/// Cuadres de ejemplo de los cobradores en los últimos días (no hoy).
abstract class MockClosings {
  static List<CashClosing> generate(
    DateTime now,
    List<Payment> payments,
    List<Loan> loans,
    List<Expense> expenses,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final list = <CashClosing>[];
    for (var back = 1; back <= 4; back++) {
      final day = today.subtract(Duration(days: back));
      for (final (i, (uid, name)) in MockLoans.collectors.indexed) {
        final s = CashSummary.of(
          day: day,
          uid: uid,
          name: name,
          payments: payments,
          loans: loans,
          expenses: expenses,
        );
        if (s.isEmpty) continue;
        const opening = 500.0;
        // Un faltante de ejemplo para ver cómo se muestra.
        final diff = back == 2 && i == 1 ? -100.0 : 0.0;
        list.add(
          CashClosing(
            id: CashClosing.idFor(uid, day),
            day: day,
            byUid: uid,
            byName: name,
            openingCash: opening,
            cashIn: s.cashIn,
            transferIn: s.transferIn,
            cashLoans: s.cashLoans,
            cashExpenses: s.cashExpenses,
            counted: opening + s.netCash + diff,
            paymentsCount: s.paymentsCount,
            status: back > 1 ? ClosingStatus.approved : ClosingStatus.pending,
            reviewedBy: back > 1 ? 'Francisco' : null,
            createdAt: day.add(const Duration(hours: 18)),
          ),
        );
      }
    }
    return list;
  }

  /// Fondos de ejemplo: 500 a cada cobrador los últimos días; hoy solo a
  /// Pedro, para ver cómo luce un cobrador sin fondo asignado.
  static List<CashFund> funds(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (var back = 0; back <= 4; back++)
        for (final (uid, name) in MockLoans.collectors)
          if (back > 0 || uid == MockLoans.collectors.first.$1)
            CashFund(
              id: CashFund.idFor(uid, today.subtract(Duration(days: back))),
              day: today.subtract(Duration(days: back)),
              uid: uid,
              name: name,
              amount: 500,
              assignedBy: 'Francisco',
              assignedAt: today
                  .subtract(Duration(days: back))
                  .add(const Duration(hours: 7, minutes: 45)),
            ),
    ];
  }
}
