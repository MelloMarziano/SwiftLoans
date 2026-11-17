import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:swiftloans/app/core/services/printer_service.dart';
import 'package:swiftloans/app/core/services/settings_service.dart';
import 'package:swiftloans/app/core/utils/date_period.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';
import 'package:swiftloans/app/modules/documents/document_actions.dart';
import 'package:swiftloans/app/modules/documents/documents.dart';

import 'helpers.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('el recibo se convierte en imagen al ancho del papel', (t) async {
    await t.runAsync(() async {
      await setUpSampleCompany();
      Get.put(PrinterService());
    });
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    final payment = Get.find<LoanRepository>().payments.first;
    final settings = Get.find<SettingsService>();

    for (final paper in PaperWidth.values) {
      settings.paperWidth.value = paper;
      final png = await t.runAsync(
        () => DocumentActions.render(
          ReceiptDoc(payment: payment),
          forPrint: true,
        ),
      );
      final image = img.decodePng(png!)!;
      expect(image.width, paper.dots);
      expect(image.height, greaterThan(image.width));
    }

    // Para compartir: a 3x, nítido en WhatsApp.
    final share = await t.runAsync(
      () =>
          DocumentActions.render(ReceiptDoc(payment: payment), forPrint: false),
    );
    expect(img.decodePng(share!)!.width, 360 * 3);
  });

  test('sin impresora elegida, imprimir explica qué hacer', () async {
    await setUpSampleCompany();
    final printer = Get.put(PrinterService());
    expect(printer.isReady, isFalse);
  });

  test('describe el periodo para los documentos', () {
    final now = DateTime(2026, 11, 16, 15);
    expect(DatePeriod.today.describe(now), 'Hoy: 16/11/2026');
    expect(DatePeriod.month.describe(now), 'Este mes: 01/11/2026 – 16/11/2026');
    expect(DatePeriod.week.describe(now), 'Esta semana: 16/11/2026');
  });
}
