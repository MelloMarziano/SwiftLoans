import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/key_value_store.dart';
import 'package:swiftloans/app/core/services/settings_service.dart';
import 'package:swiftloans/app/data/models/loan_terms.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  SettingsService create(KeyValueStore store) =>
      SettingsService(store: store)..onInit();

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('valores de fábrica', () {
    final s = create(MemoryStore());
    expect(s.businessName.value, 'SwiftLoans');
    expect(s.defaultRate.value, 20);
    expect(s.routes, ['OFICINA', 'RUTA 1', 'RUTA 2', 'RUTA 3']);
    expect(s.printerType.value, PrinterType.bluetooth);
  });

  test('la impresora se guarda en el teléfono', () async {
    final store = MemoryStore();
    create(store)
      ..printerType.value = PrinterType.none
      ..copies.value = 2;
    await flush();
    final reloaded = create(store);
    expect(reloaded.printerType.value, PrinterType.none);
    expect(reloaded.copies.value, 2);

    reloaded.resetDevice();
    expect(reloaded.printerType.value, PrinterType.bluetooth);
    expect(create(store).copies.value, 1);
  });

  test('los ajustes de la empresa se cargan y se avisan al cambiar', () async {
    final s = create(MemoryStore());
    final saved = <Map<String, dynamic>>[];
    s.onCompanyChanged = saved.add;

    s.applyCompany({
      'name': 'Préstamos Juan',
      'rate': 15, // un entero también se lee como double
      'frequency': 'weekly',
      'routes': ['NORTE', 'SUR'],
    });
    expect(s.businessName.value, 'Préstamos Juan');
    expect(s.defaultRate.value, 15.0);
    expect(s.defaultFrequency.value, PaymentFrequency.weekly);
    expect(s.routes, ['NORTE', 'SUR']);
    expect(s.businessPhone.value, '');
    // Cargar no vuelve a guardar.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(saved, isEmpty);

    s.businessPhone.value = '809-555-1234';
    s.routes.add('ESTE');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(saved, hasLength(1)); // los cambios seguidos se agrupan
    expect(saved.single['phone'], '809-555-1234');
    expect(saved.single['routes'], ['NORTE', 'SUR', 'ESTE']);

    s.resetCompany();
    expect(s.businessName.value, 'SwiftLoans');
    expect(s.routes, hasLength(4));
  });

  test('los ajustes viejos del teléfono se ofrecen para subirlos', () {
    final store = MemoryStore()
      ..write('business.name', 'Viejo')
      ..write('loan.rate', 18);
    final s = create(store);
    expect(s.legacyCompany, {'name': 'Viejo', 'rate': 18});
    s.clearLegacyCompany();
    expect(create(store).legacyCompany, isNull);
  });
}
