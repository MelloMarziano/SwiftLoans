import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/utils/input_formatters.dart';
import 'package:swiftloans/app/data/models/client.dart';
import 'package:swiftloans/app/data/repositories/client_repository.dart';
import 'package:swiftloans/app/modules/client_form/client_form_controller.dart';

import 'helpers.dart';

void main() {
  late ClientRepository repo;

  setUp(() async {
    await setUpSampleCompany();
    repo = Get.find<ClientRepository>();
  });

  tearDown(Get.reset);

  test('crear asigna el siguiente ID numérico', () async {
    final created = await repo.create(
      const Client(id: '', name: 'Nuevo Cliente'),
    );
    await settle();
    expect(created.id, isNot(''));
    expect(repo.byId(created.id)?.name, 'Nuevo Cliente');
    expect(repo.clients.length, 179);
  });

  test('editar conserva estado, préstamo y saldo', () async {
    final original = repo.byId('43')!;
    await repo.update(original.copyWith(phone: '809-555-1234'));
    await settle();
    final updated = repo.byId('43')!;
    expect(updated.phone, '809-555-1234');
    expect(updated.loanStatus, original.loanStatus);
    expect(updated.alias, 'El Marron');
    expect(updated.balance, original.balance);
  });

  test('detecta cédula duplicada ignorando el propio cliente', () {
    final withDoc = repo.clients.firstWhere((c) => c.document != null);
    expect(repo.documentInUse(withDoc.document!), isTrue);
    expect(
      repo.documentInUse(withDoc.document!, exceptId: withDoc.id),
      isFalse,
    );
  });

  test('validaciones del formulario', () {
    final form = Get.put(ClientFormController())..submitted.value = true;
    expect(form.errorFor('name'), isNotNull);
    expect(form.errorFor('phone'), isNotNull);

    form.name.text = 'Ana Pérez';
    form.phone.text = '809-555-1234';
    form.document.text = '001-123';
    expect(form.errorFor('name'), isNull);
    expect(form.errorFor('phone'), isNull);
    expect(form.errorFor('document'), 'La cédula tiene 11 dígitos');
  });

  test('máscaras de cédula y teléfono', () {
    String apply(MaskedDigitsFormatter f, String text) => f
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
        .text;

    expect(
      apply(MaskedDigitsFormatter.cedula(), '00112345678'),
      '001-1234567-8',
    );
    expect(
      apply(MaskedDigitsFormatter.phone(), '8095551234999'),
      '809-555-1234',
    );
  });
}
