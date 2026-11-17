import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/models/company.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/sources/company_data_source.dart';
import 'auth_service.dart';

/// Modo demo para mostrar la app a posibles clientes: entra sin cuenta, con
/// datos de ejemplo en memoria. Todo funciona, pero nada se guarda en la
/// base de datos y al salir vuelve a empezar.
abstract class DemoMode {
  static const companyId = 'demo';

  static const owner = AppUser(
    uid: 'demo-owner',
    username: 'demo',
    name: 'Francisco',
    role: UserRole.owner,
    companyId: companyId,
  );

  /// Coincide con el cobrador de los datos de ejemplo (cobros, fondo...).
  static const collector = AppUser(
    uid: 'c1',
    username: 'demo.cobrador',
    name: 'Pedro Cobrador',
    role: UserRole.collector,
    companyId: companyId,
  );

  static bool isDemo(AppUser? user) => user?.companyId == companyId;

  static bool get active =>
      Get.isRegistered<AuthService>() &&
      isDemo(Get.find<AuthService>().user.value);

  /// Fuente de datos según la empresa: ejemplo para la demo, real para las
  /// demás.
  static CompanyDataSource Function(String) sourceFactory(
    CompanyDataSource Function(String) real,
  ) =>
      (id) => id == companyId ? SampleCompanyDataSource() : real(id);

  /// Empresa y equipo de ejemplo (pantalla de Usuarios en la demo).
  static InMemoryAdminRepository adminRepository() => InMemoryAdminRepository(
    companies: const [
      Company(
        id: companyId,
        name: 'Préstamos Demo',
        ownerUid: 'demo-owner',
        ownerName: 'Francisco',
        maxUsers: 5,
        userCount: 3,
      ),
    ],
    users: [
      owner,
      collector,
      const AppUser(
        uid: 'c2',
        username: 'demo.luis',
        name: 'Luis Cobrador',
        role: UserRole.collector,
        companyId: companyId,
      ),
    ],
  );
}

/// Usa el repositorio de ejemplo mientras la sesión es demo y el real en
/// cualquier otro caso.
class DemoAwareAdminRepository implements AdminRepository {
  DemoAwareAdminRepository(this._real, this._demo);

  final AdminRepository _real;
  final AdminRepository _demo;

  AdminRepository get _repo => DemoMode.active ? _demo : _real;

  @override
  Stream<List<Company>> watchCompanies() => _repo.watchCompanies();

  @override
  Stream<Company?> watchCompany(String companyId) =>
      _repo.watchCompany(companyId);

  @override
  Stream<List<AppUser>> watchUsers(String companyId) =>
      _repo.watchUsers(companyId);

  @override
  Stream<List<CompanyClientRow>> watchClients(String companyId) =>
      _repo.watchClients(companyId);

  @override
  Future<CompanyStats> stats(String companyId) => _repo.stats(companyId);

  @override
  Future<Company> createCompany({
    required String name,
    String? rnc,
    String? phone,
    required int maxUsers,
    required NewUser owner,
  }) => _repo.createCompany(
    name: name,
    rnc: rnc,
    phone: phone,
    maxUsers: maxUsers,
    owner: owner,
  );

  @override
  Future<void> updateCompany(String companyId, {bool? active, int? maxUsers}) =>
      _repo.updateCompany(companyId, active: active, maxUsers: maxUsers);

  @override
  Future<AppUser> createUser({
    required String companyId,
    required NewUser user,
  }) => _repo.createUser(companyId: companyId, user: user);

  @override
  Future<void> setUserActive(String uid, {required bool active}) =>
      _repo.setUserActive(uid, active: active);
}
