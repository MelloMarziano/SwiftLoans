import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/repositories/client_repository.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';
import 'package:swiftloans/app/modules/home/home_controller.dart';
import 'package:swiftloans/main.dart';

void main() {
  testWidgets('Inicio se actualiza al registrar un cobro', (t) async {
    t.view.physicalSize = const Size(390, 1500);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    Get.reset();

    await t.pumpWidget(const SwiftLoansApp());
    await t.pumpAndSettle();
    final home = Get.find<HomeController>();
    double weekCollections() =>
        home.weeklyFlow.fold(0.0, (s, d) => s + d.collections);
    final before = weekCollections();

    final loans = Get.find<LoanRepository>();
    final client = Get.find<ClientRepository>().clients.firstWhere(
      (c) => c.hasLoan,
    );
    await t.runAsync(
      () => loans.applyPayment(
        loan: loans.activeLoanOf(client.id)!,
        amount: 600,
        method: PaymentMethod.cash,
      ),
    );
    await t.pumpAndSettle();

    // "Cobros" de la semana en la tarjeta de Cobros vs. desembolsos.
    expect(weekCollections(), closeTo(before + 600, 0.01));
  });
}
