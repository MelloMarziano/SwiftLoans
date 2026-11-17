import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/finance/cash_summary.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/models/cash_closing.dart';
import 'package:swiftloans/app/data/models/expense.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/repositories/closing_repository.dart';
import 'package:swiftloans/app/data/repositories/expense_repository.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';
import 'package:swiftloans/app/modules/cash_closing/cash_closing_controller.dart';

import 'helpers.dart';

void main() {
  tearDown(Get.reset);

  test(
    'lo esperado = fondo + cobros en efectivo − préstamos − gastos',
    () async {
      await setUpSampleCompany(); // Pedro Cobrador (c1)
      final c = Get.put(CashClosingController());
      await settle();

      final loans = Get.find<LoanRepository>();
      final before = c.mySummary.cashIn;
      await loans.applyPayment(
        loan: loans.loans.firstWhere((l) => !l.isPaidOff),
        amount: 700,
        method: PaymentMethod.cash,
      );
      await loans.applyPayment(
        loan: loans.loans.firstWhere((l) => !l.isPaidOff),
        amount: 300,
        method: PaymentMethod.transfer,
      );
      await Get.find<ExpenseRepository>().add(
        amount: 150,
        category: ExpenseCategory.fuel,
        method: PaymentMethod.cash,
      );
      await settle();

      final s = c.mySummary;
      expect(s.cashIn, closeTo(before + 700, 0.01));
      expect(s.transferIn, greaterThanOrEqualTo(300));
      // Pedro tiene asignado un fondo de 500 en los datos de ejemplo.
      expect(c.opening, 500);
      expect(c.myFund?.assignedBy, 'Francisco');
      expect(
        c.expected,
        closeTo(500 + s.cashIn - s.cashLoans - s.cashExpenses, 0.01),
      );
      expect(s.cashExpenses, greaterThanOrEqualTo(150));
    },
  );

  test('contar por billetes y cuadrar', () async {
    await setUpSampleCompany();
    final c = Get.put(CashClosingController());
    await settle();

    c.byDenomination.value = false;
    c.totalController.text = c.expected.toStringAsFixed(2);
    expect(ClosingBalance.of(c.difference), ClosingBalance.even);

    c.byDenomination.value = true;
    c.setCount(1000, 2);
    c.setCount(25, 3);
    expect(c.counted, 2075);
    c.setCount(25, -4);
    expect(c.counts[25], 0);
  });

  test('el cuadre se guarda una vez y el dueño lo revisa', () async {
    await setUpSampleCompany();
    final repo = Get.find<ClosingRepository>();
    final c = Get.put(CashClosingController());
    await settle();

    expect(c.myClosing, isNull);
    final s = c.mySummary;
    final closing = CashClosing(
      id: CashClosing.idFor('c1', c.day.value),
      day: c.day.value,
      byUid: 'c1',
      byName: 'Pedro Cobrador',
      openingCash: 500,
      cashIn: s.cashIn,
      transferIn: s.transferIn,
      cashLoans: s.cashLoans,
      cashExpenses: s.cashExpenses,
      counted: 500 + s.netCash - 100,
      createdAt: DateTime.now(),
    );
    await repo.add(closing);
    await settle();
    expect(c.myClosing?.difference, closeTo(-100, 0.01));
    expect(ClosingBalance.of(c.myClosing!.difference), ClosingBalance.short);
    expect(() => repo.add(closing), throwsA(anything));

    // Datos guardados y leídos igual (Firestore).
    final copy = CashClosing.fromMap(closing.id, closing.toMap());
    expect(copy.expected, closeTo(closing.expected, 0.01));

    // El dueño ve el equipo y lo marca revisado.
    Get.find<AuthService>().user.value = const AppUser(
      uid: 'demo-owner',
      username: 'francisco',
      name: 'Francisco',
      role: UserRole.owner,
      companyId: 'demo',
    );
    await settle();
    expect(c.canReview, isTrue);
    final row = c.team.firstWhere((r) => r.uid == 'c1');
    expect(row.closing?.status, ClosingStatus.pending);
    // Luis (c2) cobró hoy pero no ha cuadrado: aparece primero.
    expect(c.team.first.closing, isNull);

    await c.approve(row.closing!);
    await settle();
    expect(repo.byId(closing.id)!.status, ClosingStatus.approved);
    expect(repo.byId(closing.id)!.reviewedBy, 'Francisco');
  });

  test('los cuadres de ejemplo cuadran con los movimientos del día', () async {
    await setUpSampleCompany();
    await settle();
    final repo = Get.find<ClosingRepository>();
    expect(repo.closings, isNotEmpty);
    final x = repo.closings.first;
    final s = CashSummary.of(
      day: x.day,
      uid: x.byUid,
      name: x.byName,
      payments: Get.find<LoanRepository>().allPayments,
      loans: Get.find<LoanRepository>().loans,
      expenses: Get.find<ExpenseRepository>().expenses,
    );
    expect(x.cashIn, closeTo(s.cashIn, 0.01));
  });

  test('solo el dueño asigna fondos; el cuadre usa el asignado', () async {
    await setUpSampleCompany(); // Pedro (cobrador)
    final repo = Get.find<ClosingRepository>();
    final c = Get.put(CashClosingController());
    await settle();

    // El cobrador no puede asignar.
    expect(
      () => c.assignFund('c2', 'Luis Cobrador', 800),
      throwsA(isA<Exception>()),
    );

    Get.find<AuthService>().user.value = const AppUser(
      uid: 'demo-owner',
      username: 'francisco',
      name: 'Francisco',
      role: UserRole.owner,
      companyId: 'demo',
    );
    await settle();
    // Luis no tiene fondo hoy en los datos de ejemplo.
    final luis = c.team.firstWhere((r) => r.uid == 'c2');
    expect(luis.fund, isNull);

    await c.assignFund('c2', 'Luis Cobrador', 800);
    await settle();
    final fund = repo.fundOf('c2', c.day.value)!;
    expect(fund.amount, 800);
    expect(fund.assignedBy, 'Francisco');
    expect(c.team.firstWhere((r) => r.uid == 'c2').fund?.amount, 800);

    // Cambiarlo reemplaza el anterior.
    await c.assignFund('c2', 'Luis Cobrador', 1000);
    await settle();
    expect(repo.funds.where((f) => f.id == fund.id).single.amount, 1000);
  });
}
