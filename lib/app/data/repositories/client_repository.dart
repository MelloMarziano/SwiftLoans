import 'dart:async';

import 'package:get/get.dart';

import '../../core/finance/loan_ledger.dart';
import '../../core/services/auth_backend.dart';
import '../../core/services/company_session.dart';
import '../models/client.dart';
import '../models/loan.dart';
import '../sources/company_data_source.dart';
import 'loan_repository.dart';

/// Clientes de la empresa en sesión. El estado de cada uno (Al día, Por
/// cobrar, Vencido...) se calcula con sus préstamos y la fecha de hoy.
class ClientRepository extends GetxService {
  final _session = Get.find<CompanySession>();
  final _loans = Get.find<LoanRepository>();

  final _raw = <Client>[].obs;
  final clients = <Client>[].obs;
  StreamSubscription<List<Client>>? _sub;

  CompanyDataSource? get _source => _session.source.value;
  bool get isSample => _source?.isSample ?? false;

  @override
  void onInit() {
    super.onInit();
    _bind(_source);
    ever(_session.source, _bind);
    everAll([_raw, _loans.loans], (_) => _decorate());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _bind(CompanyDataSource? source) {
    _sub?.cancel();
    _raw.clear();
    if (source != null) _sub = source.watchClients().listen(_raw.assignAll);
  }

  void _decorate() {
    final now = _loans.today;
    final active = <String, Loan>{};
    for (final l in _loans.loans) {
      if (!l.isPaidOff) active.putIfAbsent(l.clientId, () => l);
    }
    clients.assignAll([
      for (final c in _raw)
        c.copyWith(
          loanStatus: active[c.id] == null
              ? ClientLoanStatus.none
              : LoanLedger.statusOf(active[c.id]!, now),
        ),
    ]);
  }

  Client? byId(String id) => clients.firstWhereOrNull((c) => c.id == id);

  int countInRoute(String route) =>
      clients.where((c) => c.route == route).length;

  /// Ya existe otro cliente con esa cédula (para evitar duplicados).
  bool documentInUse(String document, {String? exceptId}) {
    final digits = document.replaceAll('-', '');
    return clients.any(
      (c) =>
          c.id != exceptId &&
          c.document != null &&
          c.document!.replaceAll('-', '') == digits,
    );
  }

  Future<Client> create(Client draft) => _require().createClient(draft);

  Future<void> update(Client client) => _require().updateClient(client);

  Future<void> setActive(String id, {required bool active}) async {
    final client = byId(id);
    if (client != null) await update(client.copyWith(isActive: active));
  }

  Future<void> delete(String id) => _require().deleteClient(id);

  /// Al renombrar una ruta en Ajustes, sus clientes la siguen teniendo.
  Future<void> renameRoute(String from, String to) =>
      _require().renameRoute(from, to);

  /// Vuelve a cargar los datos de ejemplo (solo en modo demo).
  void resetSampleData() => _session.reload();

  CompanyDataSource _require() {
    final source = _source;
    if (source == null) {
      throw const AuthFailure('No hay una empresa activa en esta sesión.');
    }
    return source;
  }
}
