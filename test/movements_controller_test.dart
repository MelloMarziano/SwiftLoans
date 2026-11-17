import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/utils/date_period.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/models/expense.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/repositories/expense_repository.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';
import 'package:swiftloans/app/modules/movements/movements_controller.dart';

import 'helpers.dart';

void main() {
  tearDown(Get.reset);

  Future<MovementsController> controllerFor(AppUser? user) async {
    await setUpSampleCompany();
    if (user != null) Get.find<AuthService>().user.value = user;
    final c = Get.put(MovementsController());
    await settle();
    return c;
  }

  const owner = AppUser(
    uid: 'demo-owner',
    username: 'francisco',
    name: 'Francisco',
    role: UserRole.owner,
    companyId: 'demo',
  );

  test('el cobrador solo ve sus propios movimientos', () async {
    final c = await controllerFor(null); // Pedro Cobrador (c1)
    expect(c.onlyMine, isTrue);
    expect(c.all, isNotEmpty);
    expect(c.all.every((m) => m.byUid == 'c1'), isTrue);
    // Los préstamos los registró el dueño: el cobrador no los ve.
    expect(c.all.any((m) => m.kind == MovementKind.disbursement), isFalse);
  });

  test('el dueño ve todo: cobros de todos y préstamos', () async {
    final c = await controllerFor(owner);
    expect(c.onlyMine, isFalse);
    final repo = Get.find<LoanRepository>();
    final expenses = Get.find<ExpenseRepository>().expenses;
    expect(
      c.all.length,
      repo.payments.length + repo.loans.length + expenses.length,
    );
    expect(c.availablePeople.length, greaterThanOrEqualTo(3));
  });

  test('un gasto sale como salida y baja el neto', () async {
    final c = await controllerFor(owner);
    final before = c.totals;
    await Get.find<ExpenseRepository>().add(
      amount: 350,
      category: ExpenseCategory.fuel,
      method: PaymentMethod.cash,
      description: 'Gasolina',
    );
    await settle();
    final after = c.totals;
    expect(after.expenses, closeTo(before.expenses + 350, 0.01));
    expect(after.net, closeTo(before.net - 350, 0.01));
    expect(c.visible.first.kind, MovementKind.expense);
    expect(c.visible.first.byUid, 'demo-owner');
  });

  test('Hoy suma solo los movimientos de hoy', () async {
    final c = await controllerFor(owner);
    final t = c.today;
    final today = DateTime(t.year, t.month, t.day);
    final expected = Get.find<LoanRepository>().payments
        .where((p) => !p.date.isBefore(today))
        .fold<double>(0, (s, p) => s + p.amount);
    expect(c.totals.income, closeTo(expected, 0.01));
    expect(c.visible.every((m) => !m.date.isBefore(today)), isTrue);

    c.changePeriod(DatePeriod.month);
    expect(c.visible.length, greaterThanOrEqualTo(c.totals.incomeCount));
    expect(c.totals.net, closeTo(c.totals.income - c.totals.outcome, 0.01));
  });

  test('filtros por tipo, método y usuario', () async {
    final c = await controllerFor(owner);
    c.changePeriod(DatePeriod.month);

    c.applyFilters(
      kinds: {MovementKind.disbursement},
      methods: const {},
      people: const {},
    );
    expect(c.visible, isNotEmpty);
    expect(c.visible.every((m) => !m.isIncome), isTrue);

    c.applyFilters(
      kinds: const {},
      methods: {PaymentMethod.transfer},
      people: const {},
    );
    expect(c.visible.every((m) => m.method == PaymentMethod.transfer), isTrue);

    c.applyFilters(kinds: const {}, methods: const {}, people: {'c2'});
    expect(c.visible.every((m) => m.byUid == 'c2'), isTrue);

    c.resetFilters();
    expect(c.hasActiveFilters, isFalse);
  });

  test('un cobro nuevo aparece hoy firmado por quien cobró', () async {
    final c = await controllerFor(null);
    final repo = Get.find<LoanRepository>();
    final before = c.totals.income;
    final loan = repo.loans.firstWhere((l) => !l.isPaidOff);
    final payment = await repo.applyPayment(
      loan: loan,
      amount: 500,
      method: PaymentMethod.cash,
    );
    await settle();

    expect(payment.collectorUid, 'c1');
    expect(c.totals.income, closeTo(before + 500, 0.01));
    expect(c.visible.first.reference, payment.id);
    expect(c.days.first.items.first.signed, 500);
  });
}
