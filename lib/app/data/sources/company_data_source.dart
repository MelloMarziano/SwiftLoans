import 'dart:async';

import '../../core/services/auth_backend.dart';
import '../mock/mock_clients.dart';
import '../mock/mock_closings.dart';
import '../mock/mock_expenses.dart';
import '../mock/mock_loans.dart';
import '../models/cash_closing.dart';
import '../models/client.dart';
import '../models/expense.dart';
import '../models/loan.dart';

/// Datos de UNA empresa: clientes, préstamos y pagos.
///
/// Los pagos solo se agregan (nunca se editan) y el saldo del cliente se
/// mueve con incrementos; así se puede cobrar sin conexión y dos cobradores
/// no se pisan entre sí.
abstract class CompanyDataSource {
  /// Datos de ejemplo (sin base de datos real).
  bool get isSample;

  Stream<List<Client>> watchClients();
  Stream<List<Loan>> watchLoans();
  Stream<List<Payment>> watchPayments();
  Stream<List<Expense>> watchExpenses();
  Stream<List<CashClosing>> watchClosings();
  Stream<List<CashFund>> watchFunds();

  /// Ajustes de la empresa (null = aún no se han guardado).
  Stream<Map<String, dynamic>?> watchSettings();

  /// Solo dueño/administrador. Funciona sin conexión.
  Future<void> saveSettings(Map<String, dynamic> settings);

  /// Asigna el siguiente ID numérico. Requiere conexión.
  Future<Client> createClient(Client draft);
  Future<void> updateClient(Client client);
  Future<void> deleteClient(String clientId);
  Future<void> renameRoute(String from, String to);

  /// Crea el préstamo y suma lo que se debe al saldo del cliente.
  /// Requiere conexión (usa un contador).
  Future<Loan> createLoan(Loan draft);

  /// Registra el pago y resta capital + interés del saldo del cliente.
  /// Funciona sin conexión.
  Future<void> addPayment(Payment payment);

  /// Registra un gasto. Funciona sin conexión.
  Future<void> addExpense(Expense expense);

  /// Solo dueño/administrador (lo hacen cumplir las reglas).
  Future<void> deleteExpense(String expenseId);

  /// Guarda el cuadre (uno por usuario y día). Funciona sin conexión.
  Future<void> addClosing(CashClosing closing);

  /// Dueño/administrador: marca el cuadre como revisado.
  Future<void> approveClosing(String closingId, String reviewer);

  /// Dueño/administrador: asigna (o cambia) el fondo inicial de un usuario.
  Future<void> setFund(CashFund fund);

  Future<void> dispose();
}

/// Datos de ejemplo en memoria (vistas previas, tests y modo demo).
class SampleCompanyDataSource implements CompanyDataSource {
  SampleCompanyDataSource({DateTime? today}) {
    final now = today ?? DateTime.now();
    final clients = MockClients.generate();
    final (loans, payments) = MockLoans.generate(clients, now);
    final balances = <String, double>{
      for (final l in loans) l.clientId: l.totalDue,
    };
    for (final p in payments) {
      balances[p.clientId] = balances[p.clientId]! - p.interest - p.capital;
    }
    _clients = [
      for (final c in clients)
        c.copyWith(
          balance: balances[c.id] ?? 0,
          loanStatus: ClientLoanStatus.none,
        ),
    ];
    _loans = loans;
    _payments.addAll(payments);
    _expenses.addAll(MockExpenses.generate(now));
    _closings.addAll(MockClosings.generate(now, payments, loans, _expenses));
    _funds.addAll(MockClosings.funds(now));
  }

  late List<Client> _clients;
  late List<Loan> _loans;
  final _payments = <Payment>[];
  final _expenses = <Expense>[];
  final _closings = <CashClosing>[];
  final _funds = <CashFund>[];
  Map<String, dynamic>? _settings;
  final _changes = StreamController<void>.broadcast();
  var _nextLoan = 900;

  @override
  bool get isSample => true;

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<Client>> watchClients() => _watch(() => List.of(_clients));

  @override
  Stream<List<Loan>> watchLoans() => _watch(() => List.of(_loans));

  @override
  Stream<List<Payment>> watchPayments() => _watch(() => List.of(_payments));

  @override
  Stream<List<Expense>> watchExpenses() => _watch(() => List.of(_expenses));

  @override
  Stream<List<CashClosing>> watchClosings() => _watch(() => List.of(_closings));

  @override
  Stream<List<CashFund>> watchFunds() => _watch(() => List.of(_funds));

  @override
  Stream<Map<String, dynamic>?> watchSettings() =>
      _watch(() => _settings == null ? null : Map.of(_settings!));

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    _settings = Map.of(settings);
    _changes.add(null);
  }

  @override
  Future<void> setFund(CashFund fund) async {
    _funds
      ..removeWhere((f) => f.id == fund.id)
      ..add(fund);
    _changes.add(null);
  }

  @override
  Future<Client> createClient(Client draft) async {
    final next =
        _clients.fold<int>(
          0,
          (m, c) => (int.tryParse(c.id) ?? 0) > m ? int.parse(c.id) : m,
        ) +
        1;
    final client = Client.fromMap('$next', {
      ...draft.toMap(),
      'createdAt': DateTime.now(),
    });
    _clients.add(client);
    _changes.add(null);
    return client;
  }

  @override
  Future<void> updateClient(Client client) async {
    final i = _clients.indexWhere((c) => c.id == client.id);
    if (i != -1) _clients[i] = client.copyWith(balance: _clients[i].balance);
    _changes.add(null);
  }

  @override
  Future<void> deleteClient(String clientId) async {
    _clients.removeWhere((c) => c.id == clientId);
    _changes.add(null);
  }

  @override
  Future<void> renameRoute(String from, String to) async {
    _clients = [
      for (final c in _clients) c.route == from ? c.copyWith(route: to) : c,
    ];
    _changes.add(null);
  }

  @override
  Future<Loan> createLoan(Loan draft) async {
    final loan = draft.withId('P-${_nextLoan++}');
    _loans.add(loan);
    _addBalance(loan.clientId, loan.totalDue);
    _changes.add(null);
    return loan;
  }

  @override
  Future<void> addPayment(Payment payment) async {
    _payments.add(payment);
    _addBalance(payment.clientId, -(payment.interest + payment.capital));
    _changes.add(null);
  }

  @override
  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    _changes.add(null);
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    _expenses.removeWhere((e) => e.id == expenseId);
    _changes.add(null);
  }

  @override
  Future<void> addClosing(CashClosing closing) async {
    if (_closings.any((c) => c.id == closing.id)) {
      throw const AuthFailure('Ya existe un cuadre para ese día.');
    }
    _closings.add(closing);
    _changes.add(null);
  }

  @override
  Future<void> approveClosing(String closingId, String reviewer) async {
    final i = _closings.indexWhere((c) => c.id == closingId);
    if (i == -1) return;
    final c = _closings[i];
    _closings[i] = CashClosing.fromMap(c.id, {
      ...c.toMap(),
      'status': ClosingStatus.approved.name,
      'reviewedBy': reviewer,
      'reviewedAt': DateTime.now(),
    });
    _changes.add(null);
  }

  void _addBalance(String clientId, double delta) {
    final i = _clients.indexWhere((c) => c.id == clientId);
    if (i == -1) throw const AuthFailure('El cliente no existe.');
    _clients[i] = _clients[i].copyWith(balance: _clients[i].balance + delta);
  }

  @override
  Future<void> dispose() => _changes.close();
}
