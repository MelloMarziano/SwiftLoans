import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_backend.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/services/company_session.dart';
import 'package:swiftloans/app/core/services/demo_mode.dart';
import 'package:swiftloans/app/core/services/key_value_store.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/repositories/admin_repository.dart';
import 'package:swiftloans/app/data/sources/company_data_source.dart';

/// Fuente "real" de prueba para distinguirla de la de ejemplo.
class _RealSource extends SampleCompanyDataSource {
  @override
  bool get isSample => false;
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('la demo usa datos de ejemplo y empieza de cero cada vez', () async {
    final auth = Get.put(
      AuthService(backend: FakeAuthBackend(), store: MemoryStore()),
    );
    final session = Get.put(
      CompanySession(DemoMode.sourceFactory((_) => _RealSource())),
    );

    auth.startDemo(DemoMode.owner);
    expect(DemoMode.active, isTrue);
    final first = session.source.value!;
    expect(first.isSample, isTrue);

    await auth.signOut();
    expect(DemoMode.active, isFalse);
    expect(session.source.value, isNull);

    auth.startDemo(DemoMode.collector);
    expect(identical(session.source.value, first), isFalse);

    // Una empresa real usa la fuente real.
    auth.user.value = const AppUser(
      uid: 'x',
      username: 'x',
      name: 'X',
      role: UserRole.owner,
      companyId: 'abc123',
    );
    expect(session.source.value!.isSample, isFalse);
  });

  test('en la demo el equipo es de ejemplo; fuera, el real', () async {
    final auth = Get.put(
      AuthService(backend: FakeAuthBackend(), store: MemoryStore()),
    );
    final real = InMemoryAdminRepository();
    final repo = DemoAwareAdminRepository(real, DemoMode.adminRepository());

    auth.startDemo(DemoMode.owner);
    final users = await repo.watchUsers(DemoMode.companyId).first;
    expect(users.map((u) => u.name), contains('Luis Cobrador'));

    await auth.signOut();
    expect(await repo.watchUsers(DemoMode.companyId).first, isEmpty);
  });
}
