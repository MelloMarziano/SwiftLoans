import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';
import 'package:swiftloans/app/modules/loans/loans_controller.dart';

import 'helpers.dart';

void main() {
  late LoansController c;

  setUp(() async {
    await setUpSampleCompany();
    c = Get.put(LoansController());
    await settle();
  });
  tearDown(Get.reset);

  test('cada préstamo aparece con su estado y las pestañas cuadran', () {
    expect(c.rows, isNotEmpty);
    expect(c.rows.length, Get.find<LoanRepository>().loans.length);
    expect(
      c.countFor(LoanTab.active) + c.countFor(LoanTab.paidOff),
      c.countFor(LoanTab.all),
    );
    // Por defecto se ven los activos.
    expect(c.visible.length, c.countFor(LoanTab.active));
    expect(c.visible.every((r) => r.status != LoanStatus.paidOff), isTrue);
  });

  test('el resumen suma los saldos de los préstamos activos', () {
    final expected = c.rows
        .where((r) => r.status != LoanStatus.paidOff)
        .fold<double>(0, (s, r) => s + r.snapshot.balance);
    expect(c.portfolio, closeTo(expected, 0.01));
    expect(c.overdueCount, c.countFor(LoanTab.overdue));
  });

  test('pestaña Vencidos solo muestra atrasados', () {
    c.changeTab(LoanTab.overdue);
    expect(c.visible.length, c.overdueCount);
    expect(c.visible.every((r) => r.snapshot.overdueCount > 0), isTrue);
  });

  test('busca por cliente y por número de préstamo', () async {
    final target = c.rows.first;
    c.changeTab(LoanTab.all);
    c.search(target.loan.id.toLowerCase());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(c.visible.map((r) => r.loan.id), contains(target.loan.id));

    c.search(target.clientName.toUpperCase());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(c.visible.every((r) => r.clientName == target.clientName), isTrue);
  });

  test('filtro por frecuencia y orden por saldo', () {
    c.changeTab(LoanTab.all);
    final freq = c.rows.first.loan.frequency;
    c.applyFilters(
      frequencies: {freq},
      routes: const {},
      sort: LoanSort.balance,
    );
    expect(c.visible.every((r) => r.loan.frequency == freq), isTrue);
    for (var i = 1; i < c.visible.length; i++) {
      expect(
        c.visible[i - 1].snapshot.balance >= c.visible[i].snapshot.balance,
        isTrue,
      );
    }
    expect(c.hasActiveFilters, isTrue);
    c.resetFilters();
    expect(c.hasActiveFilters, isFalse);
  });

  test('saldar un préstamo lo pasa a Saldados', () async {
    final repo = Get.find<LoanRepository>();
    final row = c.rows.firstWhere((r) => r.status != LoanStatus.paidOff);
    final before = c.countFor(LoanTab.paidOff);
    await repo.applyPayment(
      loan: row.loan,
      amount: row.snapshot.balance,
      method: PaymentMethod.cash,
    );
    await settle();
    expect(c.rowById(row.loan.id)!.status, LoanStatus.paidOff);
    expect(c.countFor(LoanTab.paidOff), before + 1);
    expect(repo.paymentsOfLoan(row.loan.id), isNotEmpty);
  });
}
