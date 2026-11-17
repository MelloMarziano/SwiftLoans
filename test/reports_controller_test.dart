import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/utils/date_period.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/models/expense.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/repositories/expense_repository.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';
import 'package:swiftloans/app/modules/reports/reports_controller.dart';

import 'helpers.dart';

void main() {
  tearDown(Get.reset);

  Future<ReportsController> asOwner() async {
    await setUpSampleCompany();
    Get.find<AuthService>().user.value = const AppUser(
      uid: 'demo-owner',
      username: 'francisco',
      name: 'Francisco',
      role: UserRole.owner,
      companyId: 'demo',
    );
    final c = Get.put(ReportsController());
    await settle();
    return c;
  }

  test('ganancia = interés + mora − gastos', () async {
    final c = await asOwner();
    expect(c.collected, greaterThan(0));
    expect(
      c.profit,
      closeTo(c.collectedInterest + c.collectedLateFee - c.spent, 0.01),
    );
    expect(
      c.collected,
      closeTo(
        c.collectedCapital + c.collectedInterest + c.collectedLateFee,
        0.05,
      ),
    );

    final before = c.profit;
    await Get.find<ExpenseRepository>().add(
      amount: 1000,
      category: ExpenseCategory.other,
      method: PaymentMethod.cash,
    );
    await settle();
    expect(c.profit, closeTo(before - 1000, 0.01));
  });

  test('la cartera por tramos suma el total y cuadra con Préstamos', () async {
    final c = await asOwner();
    final rows = c.aging;
    final sum = rows.fold<double>(0, (s, r) => s + r.balance);
    expect(sum, closeTo(c.portfolio, 0.01));
    final open = Get.find<LoanRepository>().loans.where((l) => !l.isPaidOff);
    expect(rows.fold<int>(0, (s, r) => s + r.count), open.length);
    expect(c.atRiskRatio, inInclusiveRange(0, 1));
    expect(c.mostOverdue.length, lessThanOrEqualTo(5));
  });

  test('efectividad: lo pagado nunca supera lo que vencía', () async {
    final c = await asOwner();
    final (expected, paid) = c.collectionEffectiveness;
    expect(expected, greaterThan(0));
    expect(paid, lessThanOrEqualTo(expected + 0.01));
  });

  test(
    'el gráfico agrupa por día en la semana y por semana en el mes',
    () async {
      final c = await asOwner();
      c.period.value = DatePeriod.today;
      expect(c.flow, isEmpty);

      c.period.value = DatePeriod.month;
      final total = c.flow.fold<double>(0, (s, d) => s + d.collections);
      expect(total, closeTo(c.collected, 0.01));
    },
  );

  test('el cobrador solo ve sus cifras', () async {
    await setUpSampleCompany(); // Pedro Cobrador (c1)
    final c = Get.put(ReportsController());
    await settle();
    expect(c.onlyMine, isTrue);
    expect(c.periodPayments.every((p) => p.collectorUid == 'c1'), isTrue);
    expect(c.periodExpenses.every((e) => e.byUid == 'c1'), isTrue);
    expect(c.periodLoans, isEmpty);
    expect(c.byPerson.length, lessThanOrEqualTo(1));
  });
}
