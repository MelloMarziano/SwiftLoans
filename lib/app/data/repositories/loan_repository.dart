import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/finance/loan_ledger.dart';
import '../../core/services/auth_backend.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/company_session.dart';
import '../../core/services/session_service.dart';
import '../models/loan.dart';
import '../sources/company_data_source.dart';

/// Préstamos y pagos de la empresa en sesión.
///
/// Los préstamos se guardan con su calendario original; lo pagado de cada
/// cuota se reconstruye aplicando los pagos en orden. Así un pago nunca
/// modifica el préstamo y se puede registrar sin conexión.
class LoanRepository extends GetxService {
  final _session = Get.find<CompanySession>();

  final _rawLoans = <Loan>[].obs;
  final payments = <Payment>[].obs;

  /// Préstamos con los pagos ya aplicados.
  final loans = <Loan>[].obs;

  /// Pagos recién registrados que aún no llegan por el stream (para poder
  /// mostrar el recibo de inmediato, incluso sin conexión).
  final _pending = <String, Payment>{};
  final _subs = <StreamSubscription<dynamic>>[];

  DateTime get today => DateTime.now();

  CompanyDataSource? get _source => _session.source.value;
  bool get isSample => _source?.isSample ?? false;

  @override
  void onInit() {
    super.onInit();
    _bind(_source);
    ever(_session.source, _bind);
    everAll([_rawLoans, payments], (_) => _recompute());
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }

  void _bind(CompanyDataSource? source) {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _pending.clear();
    _rawLoans.clear();
    payments.clear();
    if (source == null) return;
    _subs
      ..add(source.watchLoans().listen(_rawLoans.assignAll))
      ..add(source.watchPayments().listen(payments.assignAll));
  }

  void _recompute() {
    final byLoan = <String, List<Payment>>{};
    for (final p in payments) {
      _pending.remove(p.id);
      byLoan.putIfAbsent(p.loanId, () => []).add(p);
    }
    loans.assignAll([
      for (final loan in _rawLoans)
        (byLoan[loan.id] ?? const <Payment>[]).fold(
          loan,
          (l, p) => LoanLedger.apply(l, PaymentAllocation.of(p)),
        ),
    ]);
  }

  /// Préstamo vigente del cliente (el primero sin saldar).
  Loan? activeLoanOf(String clientId) =>
      loans.firstWhereOrNull((l) => l.clientId == clientId && !l.isPaidOff);

  List<Loan> activeLoansOf(String clientId) =>
      loans.where((l) => l.clientId == clientId && !l.isPaidOff).toList();

  /// Más recientes primero.
  List<Payment> paymentsOf(String clientId) =>
      [
          ...payments,
          ..._pending.values,
        ].where((p) => p.clientId == clientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Todos los pagos, incluidos los recién registrados sin conexión.
  List<Payment> get allPayments => [...payments, ..._pending.values];

  /// Pagos de un préstamo, más recientes primero.
  List<Payment> paymentsOfLoan(String loanId) =>
      [
          ...payments,
          ..._pending.values,
        ].where((p) => p.loanId == loanId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Payment? paymentById(String id) =>
      payments.firstWhereOrNull((p) => p.id == id) ?? _pending[id];

  Loan? loanById(String id) => loans.firstWhereOrNull((l) => l.id == id);

  Future<Loan> createLoan(Loan draft) {
    final me = Get.find<AuthService>().user.value;
    return _require().createLoan(
      me == null ? draft : draft.withAuthor(uid: me.uid, name: me.name),
    );
  }

  /// Reparte el pago (mora → interés → capital), lo registra y devuelve el
  /// recibo. Funciona sin conexión.
  Future<Payment> applyPayment({
    required Loan loan,
    required double amount,
    required PaymentMethod method,
  }) async {
    final now = today;
    final allocation = LoanLedger.allocate(loan, amount, now);
    final updated = LoanLedger.apply(loan, allocation);

    final payment = Payment(
      id: _receiptId(now),
      loanId: loan.id,
      clientId: loan.clientId,
      date: now,
      amount: allocation.total,
      method: method,
      lateFee: allocation.lateFee,
      interest: allocation.interest,
      capital: allocation.capital,
      installmentsCompleted: allocation.completed,
      balanceAfter: LoanLedger.snapshot(updated, now).balance,
      collector: Get.find<SessionService>().userName.value,
      collectorUid: Get.find<AuthService>().user.value?.uid,
      allocations: allocation.items,
    );
    _pending[payment.id] = payment;
    await _require().addPayment(payment);
    return payment;
  }

  /// Vuelve a cargar los datos de ejemplo (solo en modo demo).
  void resetSampleData() => _session.reload();

  CompanyDataSource _require() {
    final source = _source;
    if (source == null) {
      throw const AuthFailure('No hay una empresa activa en esta sesión.');
    }
    return source;
  }

  /// Número de recibo único aun sin conexión: fecha-hora + 3 caracteres.
  static final _random = Random();
  static String _receiptId(DateTime now) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(
      3,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return 'R-${DateFormat('yyMMdd-HHmm').format(now)}-$suffix';
  }
}
