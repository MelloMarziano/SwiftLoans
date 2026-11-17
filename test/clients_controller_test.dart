import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/data/repositories/client_repository.dart';

import 'helpers.dart';
import 'package:swiftloans/app/modules/clients/clients_controller.dart';

void main() {
  late ClientsController controller;

  setUp(() async {
    await setUpSampleCompany();
    controller = Get.put(ClientsController());
  });

  tearDown(Get.reset);

  test('totales coinciden con el diseño', () {
    expect(controller.totalCount, 178);
    expect(controller.activeCount, 168);
    expect(controller.inactiveCount, 10);
    expect(controller.withLoanCount, 44);
    expect(controller.withoutLoanCount, 134);
  });

  test('busca sin importar acentos ni mayúsculas', () async {
    controller.search('martinez');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(
      controller.visible.map((c) => c.name),
      contains('Carolina Martínez'),
    );
  });

  test('busca por alias e ID', () async {
    controller.search('marron');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(controller.visible.single.id, '43');
  });

  test('la lista refleja cambios del repositorio', () async {
    final repo = Get.find<ClientRepository>();
    final client = repo.byId('31')!;

    await repo.setActive(client.id, active: false);
    await settle();
    expect(controller.inactiveCount, 11);

    await repo.delete(client.id);
    await settle();
    expect(controller.totalCount, 177);
    expect(controller.visible.any((c) => c.id == '31'), isFalse);
  });

  test('segmentos y filtro de estado', () {
    controller.changeSegment(ClientSegment.withLoan);
    expect(controller.visible.length, 44);
    controller.changeSegment(ClientSegment.all);
    controller.applyFilters(ClientStatusFilter.inactive, ClientSort.name);
    expect(controller.visible.length, 10);
    expect(controller.hasActiveFilters, isTrue);
  });
}
