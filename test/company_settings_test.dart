import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_backend.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/services/company_session.dart';
import 'package:swiftloans/app/core/services/company_settings_sync.dart';
import 'package:swiftloans/app/core/services/key_value_store.dart';
import 'package:swiftloans/app/core/services/settings_service.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/sources/company_data_source.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  AppUser user(String uid, UserRole role, String company) => AppUser(
    uid: uid,
    username: uid,
    name: uid,
    role: role,
    companyId: company,
  );

  Future<void> wait() =>
      Future<void>.delayed(const Duration(milliseconds: 450));

  test('los ajustes son de cada empresa y solo el dueño los cambia', () async {
    // Una fuente por empresa que se conserva al cambiar de sesión.
    final sources = <String, SampleCompanyDataSource>{};
    final store = MemoryStore()..write('business.name', 'Del teléfono');
    final settings = Get.put(SettingsService(store: store));
    final auth = Get.put(
      AuthService(backend: FakeAuthBackend(), store: MemoryStore()),
    )..user.value = user('owner-a', UserRole.owner, 'a');
    Get.put(
      CompanySession(
        (id) => sources.putIfAbsent(id, SampleCompanyDataSource.new),
      ),
    );
    Get.put(CompanySettingsSync());
    await wait();

    // El dueño de A sube los ajustes que tenía su teléfono.
    expect(settings.businessName.value, 'Del teléfono');
    expect(settings.legacyCompany, isNull);

    settings.businessName.value = 'Préstamos A';
    settings.defaultRate.value = 12;
    await wait();

    // Un cobrador de A ve lo mismo pero no puede cambiarlo.
    auth.user.value = user('cob-a', UserRole.collector, 'a');
    await wait();
    expect(CompanySettingsSync.canEdit, isFalse);
    expect(settings.businessName.value, 'Préstamos A');
    settings.businessName.value = 'Hackeado';
    await wait();

    // Empresa B no ve los de A: arranca con los de fábrica.
    auth.user.value = user('owner-b', UserRole.owner, 'b');
    await wait();
    expect(settings.businessName.value, 'SwiftLoans');
    expect(settings.defaultRate.value, 20);

    // De vuelta en A: lo del cobrador no se guardó.
    auth.user.value = user('owner-a', UserRole.owner, 'a');
    await wait();
    expect(settings.businessName.value, 'Préstamos A');
    expect(settings.defaultRate.value, 12);
  });
}
