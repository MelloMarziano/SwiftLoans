import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/finance/loan_calculator.dart';
import 'package:swiftloans/app/core/finance/loan_ledger.dart';
import 'package:swiftloans/app/data/models/client.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/models/loan_terms.dart';
import 'package:swiftloans/app/data/repositories/client_repository.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';

import 'helpers.dart';

void main() {
  late ClientRepository clients;
  late LoanRepository loans;

  setUp(() async {
    await setUpSampleCompany();
    clients = Get.find<ClientRepository>();
    loans = Get.find<LoanRepository>();
  });

  tearDown(Get.reset);

  test('cada cliente con préstamo tiene un préstamo coherente', () {
    final withLoan = clients.clients.where((c) => c.hasLoan).toList();
    expect(withLoan, hasLength(44));
    for (final c in withLoan) {
      final loan = loans.activeLoanOf(c.id);
      expect(loan, isNotNull, reason: c.name);
      expect(LoanLedger.statusOf(loan!, loans.today), c.loanStatus);
      // El saldo guardado coincide con lo pendiente del préstamo.
      final pending = loan.installments.fold<double>(
        0,
        (s, i) => s + i.pending,
      );
      expect(c.balance, closeTo(pending, 0.01), reason: c.name);
    }
  });

  test('ponerse al día genera recibo y deja al cliente al día', () async {
    final client = clients.clients.firstWhere(
      (c) => c.loanStatus == ClientLoanStatus.overdue,
    );
    final loan = loans.activeLoanOf(client.id)!;
    final due = LoanLedger.snapshot(loan, loans.today).amountToBeCurrent;
    final balanceBefore = client.balance;

    final payment = await loans.applyPayment(
      loan: loan,
      amount: due,
      method: PaymentMethod.cash,
    );
    await settle();

    expect(payment.id, matches(RegExp(r'^R-\d{6}-\d{4}-[A-Z0-9]{3}$')));
    expect(payment.collector, 'Pedro Cobrador');
    expect(payment.lateFee, greaterThan(0));
    expect(payment.amount, closeTo(due, 0.001));
    expect(clients.byId(client.id)!.loanStatus, ClientLoanStatus.upToDate);
    // El más reciente primero.
    expect(loans.paymentsOf(client.id).first.id, payment.id);
    // El saldo baja solo por capital + interés (la mora no es saldo).
    expect(
      clients.byId(client.id)!.balance,
      closeTo(balanceBefore - payment.interest - payment.capital, 0.01),
    );
  });

  test('el recibo está disponible al instante (aun sin conexión)', () async {
    final client = clients.clients.firstWhere((c) => c.hasLoan);
    final loan = loans.activeLoanOf(client.id)!;
    final payment = await loans.applyPayment(
      loan: loan,
      amount: 100,
      method: PaymentMethod.cash,
    );
    // Sin esperar al stream:
    expect(loans.paymentById(payment.id), isNotNull);
  });

  test('lo pagado se reconstruye con varios pagos', () async {
    final client = clients.clients.firstWhere((c) => c.hasLoan);
    var loan = loans.activeLoanOf(client.id)!;
    final next = loan.installments.firstWhere((i) => !i.isPaid);

    await loans.applyPayment(
      loan: loan,
      amount: 100,
      method: PaymentMethod.cash,
    );
    await settle();
    loan = loans.activeLoanOf(client.id)!;
    await loans.applyPayment(
      loan: loan,
      amount: 50,
      method: PaymentMethod.transfer,
    );
    await settle();

    final rebuilt = loans
        .loanById(loan.id)!
        .installments
        .firstWhere((i) => i.number == next.number);
    final fee = LoanLedger.lateFeeFor(loan, next, loans.today);
    expect(
      rebuilt.paidLateFee + rebuilt.paidInterest + rebuilt.paidCapital,
      closeTo(150, 0.01),
      reason: 'mora pendiente era $fee',
    );
  });

  test('saldar el préstamo deja al cliente sin préstamo', () async {
    final client = clients.clients.firstWhere((c) => c.hasLoan);
    final loan = loans.activeLoanOf(client.id)!;
    final balance = LoanLedger.snapshot(loan, loans.today).balance;

    final payment = await loans.applyPayment(
      loan: loan,
      amount: balance,
      method: PaymentMethod.transfer,
    );
    await settle();

    expect(payment.balanceAfter, 0);
    expect(loans.activeLoanOf(client.id), isNull);
    expect(clients.byId(client.id)!.loanStatus, ClientLoanStatus.none);
    expect(clients.byId(client.id)!.balance, closeTo(0, 0.01));
  });

  test('crear un préstamo suma lo que se debe al saldo del cliente', () async {
    final client = clients.clients.firstWhere((c) => !c.hasLoan);
    final quote = LoanCalculator.quote(
      principal: 10000,
      monthlyRatePercent: 20,
      installments: 30,
      frequency: PaymentFrequency.daily,
      type: LoanType.interestAndCapital,
      startDate: loans.today,
    );

    final loan = await loans.createLoan(
      Loan(
        id: '',
        clientId: client.id,
        amount: quote.financedAmount,
        frequency: PaymentFrequency.daily,
        type: LoanType.interestAndCapital,
        monthlyRate: 20,
        lateFeeRate: 5,
        startDate: loans.today,
        installments: quote.schedule.map(LoanInstallment.fromSchedule).toList(),
        createdAt: loans.today,
      ),
    );
    await settle();

    expect(loan.id, startsWith('P-'));
    expect(clients.byId(client.id)!.balance, closeTo(12000, 0.01));
    expect(clients.byId(client.id)!.loanStatus, ClientLoanStatus.upToDate);
  });

  test('los modelos se guardan y leen igual (Firestore)', () {
    final loan = loans.loans.first;
    final copy = Loan.fromMap(loan.id, loan.toMap());
    expect(copy.installments.length, loan.installments.length);
    expect(copy.totalDue, closeTo(loan.totalDue, 0.001));
  });
}
