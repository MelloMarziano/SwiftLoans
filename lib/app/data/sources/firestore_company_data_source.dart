import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/auth_backend.dart';
import '../models/cash_closing.dart';
import '../models/client.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import 'company_data_source.dart';

/// Datos de una empresa en Firestore: companies/{companyId}/...
class FirestoreCompanyDataSource implements CompanyDataSource {
  FirestoreCompanyDataSource(this.companyId);

  final String companyId;
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _company =>
      _db.collection('companies').doc(companyId);
  CollectionReference<Map<String, dynamic>> get _clients =>
      _company.collection('clients');
  CollectionReference<Map<String, dynamic>> get _loans =>
      _company.collection('loans');
  CollectionReference<Map<String, dynamic>> get _payments =>
      _company.collection('payments');
  CollectionReference<Map<String, dynamic>> get _expenses =>
      _company.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _closings =>
      _company.collection('closings');
  CollectionReference<Map<String, dynamic>> get _funds =>
      _company.collection('funds');
  DocumentReference<Map<String, dynamic>> get _settings =>
      _company.collection('settings').doc('general');
  DocumentReference<Map<String, dynamic>> get _counters =>
      _company.collection('meta').doc('counters');

  @override
  bool get isSample => false;

  @override
  Stream<List<Client>> watchClients() => _clients.snapshots().map(
    (s) => [for (final d in s.docs) Client.fromMap(d.id, _dates(d.data()))],
  );

  @override
  Stream<List<Loan>> watchLoans() => _loans.snapshots().map(
    (s) => [for (final d in s.docs) Loan.fromMap(d.id, _dates(d.data()))],
  );

  @override
  Stream<List<Payment>> watchPayments() => _payments
      .orderBy('date')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) Payment.fromMap(d.id, _dates(d.data())),
        ],
      );

  @override
  Stream<List<Expense>> watchExpenses() => _expenses
      .orderBy('date')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) Expense.fromMap(d.id, _dates(d.data())),
        ],
      );

  @override
  Stream<List<CashClosing>> watchClosings() => _closings.snapshots().map(
    (s) => [
      for (final d in s.docs) CashClosing.fromMap(d.id, _dates(d.data())),
    ],
  );

  @override
  Stream<List<CashFund>> watchFunds() => _funds.snapshots().map(
    (s) => [for (final d in s.docs) CashFund.fromMap(d.id, _dates(d.data()))],
  );

  @override
  Future<void> setFund(CashFund fund) {
    _funds.doc(fund.id).set(fund.toMap()).ignore();
    return Future.value();
  }

  @override
  Stream<Map<String, dynamic>?> watchSettings() =>
      _settings.snapshots().map((d) => d.data());

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) {
    // Sin await: se guarda aunque no haya señal y se sube al volver.
    _settings.set(settings).ignore();
    return Future.value();
  }

  @override
  Future<Client> createClient(Client draft) => _guard(() async {
    final id = await _nextId('clients');
    final data = {
      ...draft.toMap(),
      'balance': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _clients.doc(id).set(data);
    return Client.fromMap(id, {...draft.toMap(), 'createdAt': DateTime.now()});
  });

  @override
  Future<void> updateClient(Client client) =>
      _guard(() => _clients.doc(client.id).update(client.toMap()));

  @override
  Future<void> deleteClient(String clientId) =>
      _guard(() => _clients.doc(clientId).delete());

  @override
  Future<void> renameRoute(String from, String to) => _guard(() async {
    final snap = await _clients.where('route', isEqualTo: from).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'route': to});
    }
    await batch.commit();
  });

  @override
  Future<Loan> createLoan(Loan draft) => _guard(() async {
    final id = 'P-${await _nextId('loans')}';
    final loan = draft.withId(id);
    await (_db.batch()
          ..set(_loans.doc(id), {
            ...loan.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..update(_clients.doc(loan.clientId), {
            'balance': FieldValue.increment(loan.totalDue),
          }))
        .commit();
    return loan;
  });

  @override
  Future<void> addPayment(Payment payment) {
    // Sin await al commit: con Firestore sin conexión la escritura queda en
    // cola y se envía al volver la señal; no hay que bloquear al cobrador.
    final batch = _db.batch()
      ..set(_payments.doc(payment.id), payment.toMap())
      ..update(_clients.doc(payment.clientId), {
        'balance': FieldValue.increment(-(payment.interest + payment.capital)),
      });
    batch.commit().ignore();
    return Future.value();
  }

  @override
  Future<void> addExpense(Expense expense) {
    // Igual que los pagos: sin await para que funcione sin conexión.
    _expenses.doc(expense.id).set(expense.toMap()).ignore();
    return Future.value();
  }

  @override
  Future<void> deleteExpense(String expenseId) =>
      _guard(() => _expenses.doc(expenseId).delete());

  @override
  Future<void> addClosing(CashClosing closing) {
    // Sin await: el cobrador puede cuadrar sin señal.
    _closings.doc(closing.id).set(closing.toMap()).ignore();
    return Future.value();
  }

  @override
  Future<void> approveClosing(String closingId, String reviewer) => _guard(
    () => _closings.doc(closingId).update({
      'status': ClosingStatus.approved.name,
      'reviewedBy': reviewer,
      'reviewedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> dispose() async {}

  /// Siguiente número consecutivo (1, 2, 3...) con una transacción.
  Future<String> _nextId(String counter) async {
    try {
      return await _db.runTransaction((tx) async {
        final snap = await tx.get(_counters);
        final next = ((snap.data()?[counter] as num?)?.toInt() ?? 0) + 1;
        tx.set(_counters, {counter: next}, SetOptions(merge: true));
        return '$next';
      });
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const AuthFailure(
          'Sin conexión. Para registrar clientes y préstamos necesitas internet.',
        );
      }
      rethrow;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw AuthFailure(switch (e.code) {
        'permission-denied' => 'No tienes permiso para esta operación.',
        'unavailable' => 'Sin conexión. Inténtalo cuando tengas internet.',
        _ => 'No se pudo guardar (${e.code}).',
      });
    }
  }

  /// Convierte los Timestamp de Firestore en DateTime (también en listas).
  static Map<String, dynamic> _dates(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, _convert(v)));

  static Object? _convert(Object? v) => switch (v) {
    Timestamp t => t.toDate(),
    Map<String, dynamic> m => _dates(m),
    List l => [for (final e in l) _convert(e)],
    _ => v,
  };
}
