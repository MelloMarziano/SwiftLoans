import 'dart:math';

import '../models/expense.dart';
import '../models/loan.dart';
import 'mock_loans.dart';

/// Gastos de ejemplo de los últimos días (cobradores y dueño).
abstract class MockExpenses {
  static const _samples = [
    (ExpenseCategory.fuel, 'Gasolina del motor', 300.0),
    (ExpenseCategory.food, 'Almuerzo en ruta', 250.0),
    (ExpenseCategory.phone, 'Recarga del celular', 100.0),
    (ExpenseCategory.transport, 'Motoconcho', 150.0),
    (ExpenseCategory.office, 'Talonarios de recibos', 450.0),
  ];

  static List<Expense> generate(DateTime now) {
    final random = Random(7);
    final day = DateTime(now.year, now.month, now.day);
    final people = [...MockLoans.collectors, ('demo-owner', 'Francisco')];
    var n = 1;

    final list = <Expense>[
      for (var back = 12; back >= 0; back--)
        for (var k = 0; k < 1 + random.nextInt(2); k++)
          () {
            final (category, description, amount) =
                _samples[random.nextInt(_samples.length)];
            final (uid, name) = people[random.nextInt(2)]; // cobradores
            final at = day
                .subtract(Duration(days: back))
                .add(Duration(hours: 9 + random.nextInt(8)));
            return Expense(
              id: 'G-${(n++).toString().padLeft(6, '0')}',
              date: at.isAfter(now)
                  ? now.subtract(const Duration(minutes: 20))
                  : at,
              amount: amount,
              category: category,
              method: PaymentMethod.cash,
              byUid: uid,
              byName: name,
              description: description,
            );
          }(),
    ];
    // Un gasto fijo del mes registrado por el dueño.
    final (ownerUid, ownerName) = people.last;
    list.add(
      Expense(
        id: 'G-${(n++).toString().padLeft(6, '0')}',
        date: DateTime(day.year, day.month, 1, 10),
        amount: 8000,
        category: ExpenseCategory.rent,
        method: PaymentMethod.transfer,
        byUid: ownerUid,
        byName: ownerName,
        description: 'Alquiler de la oficina',
      ),
    );
    return list;
  }
}
