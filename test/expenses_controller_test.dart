import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/utils/date_period.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/models/expense.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/repositories/expense_repository.dart';
import 'package:swiftloans/app/modules/expenses/expenses_controller.dart';

import 'helpers.dart';

void main() {
  tearDown(Get.reset);

  test('el cobrador registra y ve solo sus gastos; no puede borrar', () async {
    await setUpSampleCompany(); // Pedro Cobrador (c1)
    final c = Get.put(ExpensesController());
    final repo = Get.find<ExpenseRepository>();
    await settle();
    c.period.value = DatePeriod.month;

    expect(repo.canDelete, isFalse);
    expect(c.visible.every((e) => e.byUid == 'c1'), isTrue);

    final before = c.total;
    final e = await repo.add(
      amount: 250,
      category: ExpenseCategory.food,
      method: PaymentMethod.cash,
      description: '  ',
    );
    await settle();
    expect(e.id, matches(RegExp(r'^G-\d{6}-\d{4}-[A-Z0-9]{3}$')));
    expect(e.description, isNull); // vacío no se guarda
    expect(e.title, 'Comida');
    expect(c.total, closeTo(before + 250, 0.01));
    expect(c.visible.first.id, e.id);
  });

  test('el dueño ve todos, filtra por categoría y puede borrar', () async {
    await setUpSampleCompany();
    Get.find<AuthService>().user.value = const AppUser(
      uid: 'demo-owner',
      username: 'francisco',
      name: 'Francisco',
      role: UserRole.owner,
      companyId: 'demo',
    );
    final c = Get.put(ExpensesController());
    final repo = Get.find<ExpenseRepository>();
    await settle();
    c.period.value = DatePeriod.month;

    expect(repo.canDelete, isTrue);
    expect(c.visible.map((e) => e.byUid).toSet().length, greaterThan(1));
    final sum = c.byCategory.fold<double>(0, (s, p) => s + p.$2);
    expect(sum, closeTo(c.total, 0.01));

    final top = c.byCategory.first.$1;
    c.toggleCategory(top);
    expect(c.visible.every((e) => e.category == top), isTrue);

    final victim = c.visible.first;
    await repo.delete(victim);
    await settle();
    expect(c.visible.any((e) => e.id == victim.id), isFalse);
  });
}
