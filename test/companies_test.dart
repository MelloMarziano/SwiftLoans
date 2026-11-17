import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_backend.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/services/company_session.dart';
import 'package:swiftloans/app/core/services/key_value_store.dart';
import 'package:swiftloans/app/core/utils/user_validators.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/models/company.dart';
import 'package:swiftloans/app/data/repositories/admin_repository.dart';
import 'package:swiftloans/app/data/sources/company_data_source.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  NewUser newUser(String username, UserRole role) => NewUser(
    username: username,
    name: 'Nombre $username',
    password: 'clave123',
    role: role,
  );

  test('el ROOT usa la app con la empresa que elija', () async {
    final repo = Get.put<AdminRepository>(InMemoryAdminRepository());
    final a = await repo.createCompany(
      name: 'A Préstamos',
      maxUsers: 2,
      owner: newUser('ana', UserRole.owner),
    );
    final b = await repo.createCompany(
      name: 'B Préstamos',
      maxUsers: 2,
      owner: newUser('beto', UserRole.owner),
    );
    final auth = Get.put(
      AuthService(backend: FakeAuthBackend(), store: MemoryStore()),
    );
    final opened = <String>[];
    final session = Get.put(
      CompanySession((id) {
        opened.add(id);
        return SampleCompanyDataSource();
      }),
    );

    auth.user.value = const AppUser(
      uid: 'r',
      username: 'root',
      name: 'Root',
      role: UserRole.root,
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.viewing.value?.id, a.id);
    expect(session.source.value, isNotNull);

    session.enter(b);
    expect(opened, [a.id, b.id]);

    auth.user.value = null;
    expect(session.viewing.value, isNull);
    expect(session.source.value, isNull);
  });

  group('empresas', () {
    late InMemoryAdminRepository repo;
    late Company company;

    setUp(() async {
      repo = InMemoryAdminRepository();
      company = await repo.createCompany(
        name: 'Préstamos Juan',
        maxUsers: 3,
        owner: newUser('juan', UserRole.owner),
      );
    });

    test('al crear la empresa el dueño ocupa el primer cupo', () async {
      expect(company.userCount, 1);
      final users = await repo.watchUsers(company.id).first;
      expect(users.single.role, UserRole.owner);
      expect(users.single.mustChangePassword, isTrue);
    });

    test('no se puede pasar del límite de usuarios', () async {
      await repo.createUser(
        companyId: company.id,
        user: newUser('a', UserRole.collector),
      );
      await repo.createUser(
        companyId: company.id,
        user: newUser('b', UserRole.collector),
      );
      expect(
        () => repo.createUser(
          companyId: company.id,
          user: newUser('c', UserRole.collector),
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('desactivar un usuario no libera el cupo', () async {
      final a = await repo.createUser(
        companyId: company.id,
        user: newUser('a', UserRole.collector),
      );
      await repo.setUserActive(a.uid, active: false);
      final c = await repo.watchCompany(company.id).first;
      expect(c!.userCount, 2);
    });

    test('el usuario debe ser único en toda la plataforma', () async {
      final other = await repo.createCompany(
        name: 'Otra',
        maxUsers: 5,
        owner: newUser('pedro', UserRole.owner),
      );
      expect(
        () => repo.createUser(
          companyId: other.id,
          user: newUser('juan', UserRole.collector),
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('ROOT puede subir el límite', () async {
      await repo.updateCompany(company.id, maxUsers: 10);
      expect((await repo.watchCompany(company.id).first)!.freeSeats, 9);
    });
  });

  test('qué roles puede crear cada quien', () {
    expect(UserRole.owner.canCreate, [UserRole.admin, UserRole.collector]);
    expect(UserRole.admin.canCreate, [UserRole.collector]);
    expect(UserRole.collector.canCreate, isEmpty);
    expect(
      UserRole.root.canCreate,
      isEmpty,
    ); // el ROOT crea empresas, no empleados
  });

  test('validación de usuario y contraseña', () {
    expect(UserValidators.username('Juan.Perez'), isNull);
    expect(UserValidators.username('juan perez'), isNotNull);
    expect(UserValidators.username('juan@mail.com'), isNotNull);
    expect(UserValidators.password('12345'), isNotNull);
    expect(UserValidators.password('123456'), isNull);
  });

  test('empresa suspendida: sus usuarios no pueden entrar', () async {
    const owner = AppUser(
      uid: 'o1',
      username: 'juan',
      name: 'Juan',
      role: UserRole.owner,
      companyId: 'c1',
    );
    final auth = AuthService(
      backend: FakeAuthBackend(
        users: {'juan@${AuthService.usernameDomain}': ('clave123', owner)},
        suspendedCompanies: {'c1'},
      ),
      store: MemoryStore(),
    );

    await expectLater(
      auth.signIn(identifier: 'juan', password: 'clave123', remember: true),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('suspendida'),
        ),
      ),
    );
    expect(auth.isLoggedIn, isFalse);
  });
}
