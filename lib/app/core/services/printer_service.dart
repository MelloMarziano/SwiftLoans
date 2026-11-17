import 'dart:io' show Platform;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'settings_service.dart';

/// Error de impresión con un mensaje para mostrar al usuario.
class PrinterFailure implements Exception {
  const PrinterFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Impresora térmica Bluetooth (ESC/POS). Imprime documentos como imagen,
/// así salen bien las tildes, la ñ y el diseño del recibo.
class PrinterService extends GetxService {
  final _settings = Get.find<SettingsService>();

  final isPrinting = false.obs;

  /// La impresión Bluetooth funciona en Android e iOS.
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get isEnabled => _settings.printerType.value == PrinterType.bluetooth;

  /// Hay una impresora elegida y la impresión está activa.
  bool get isReady =>
      isSupported && isEnabled && _settings.printerAddress.value.isNotEmpty;

  String get printerName => _settings.printerName.value;

  PaperWidth get paper => _settings.paperWidth.value;

  /// Impresoras ya vinculadas en el Bluetooth del teléfono.
  Future<List<BluetoothInfo>> pairedPrinters() async {
    _requireSupport();
    await _ensurePermissions();
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      throw const PrinterFailure('Enciende el Bluetooth del teléfono.');
    }
    return PrintBluetoothThermal.pairedBluetooths;
  }

  /// Conecta con la impresora y la deja guardada para las próximas veces.
  Future<void> select(BluetoothInfo printer) async {
    _requireSupport();
    await PrintBluetoothThermal.disconnect;
    if (!await PrintBluetoothThermal.connect(
      macPrinterAddress: printer.macAdress,
    )) {
      throw PrinterFailure(
        'No se pudo conectar con ${printer.name}. '
        'Verifica que esté encendida y cerca.',
      );
    }
    _settings.printerName.value = printer.name;
    _settings.printerAddress.value = printer.macAdress;
  }

  Future<void> forget() async {
    if (isSupported) await PrintBluetoothThermal.disconnect;
    _settings.printerName.value = '';
    _settings.printerAddress.value = '';
  }

  /// Imprime una imagen PNG (ya al ancho del papel) las copias configuradas.
  Future<void> printPng(Uint8List png, {int? copies}) async {
    _requireSupport();
    if (!isEnabled) {
      throw const PrinterFailure(
        'La impresión está desactivada. Actívala en Ajustes → Impresora.',
      );
    }
    if (_settings.printerAddress.value.isEmpty) {
      throw const PrinterFailure(
        'No hay impresora elegida. Ve a Ajustes → Impresora → Buscar impresoras.',
      );
    }
    if (isPrinting.value) return;
    isPrinting.value = true;
    try {
      await _ensurePermissions();
      await _connect();
      final bytes = await _ticketBytes(png);
      for (var i = 0; i < (copies ?? _settings.copies.value); i++) {
        if (!await PrintBluetoothThermal.writeBytes(bytes)) {
          throw const PrinterFailure(
            'Se perdió la conexión con la impresora. Intenta de nuevo.',
          );
        }
      }
    } finally {
      isPrinting.value = false;
    }
  }

  Future<void> _connect() async {
    if (await PrintBluetoothThermal.connectionStatus) return;
    final ok = await PrintBluetoothThermal.connect(
      macPrinterAddress: _settings.printerAddress.value,
    );
    if (!ok) {
      throw PrinterFailure(
        'No se pudo conectar con ${printerName.isEmpty ? 'la impresora' : printerName}. '
        'Verifica que esté encendida y con papel.',
      );
    }
  }

  /// Convierte la imagen a comandos ESC/POS. Se envía en franjas para que
  /// las impresoras con poca memoria no se saturen.
  Future<List<int>> _ticketBytes(Uint8List png) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paper == PaperWidth.mm58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    var image = img.decodePng(png);
    if (image == null) {
      throw const PrinterFailure('No se pudo preparar el documento.');
    }
    if (image.width != paper.dots) {
      image = img.copyResize(
        image,
        width: paper.dots,
        interpolation: img.Interpolation.average,
      );
    }

    const slice = 240;
    final bytes = <int>[...generator.reset()];
    for (var y = 0; y < image.height; y += slice) {
      final part = img.copyCrop(
        image,
        x: 0,
        y: y,
        width: image.width,
        height: (image.height - y).clamp(0, slice),
      );
      bytes.addAll(generator.imageRaster(part));
    }
    bytes
      ..addAll(generator.feed(2))
      ..addAll(generator.cut());
    return bytes;
  }

  Future<void> _ensurePermissions() async {
    if (!Platform.isAndroid) return;
    final result = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    if (result.values.any((s) => !s.isGranted)) {
      throw const PrinterFailure(
        'SwiftLoans necesita permiso de Bluetooth para imprimir. '
        'Actívalo en los ajustes del teléfono.',
      );
    }
  }

  void _requireSupport() {
    if (!isSupported) {
      throw const PrinterFailure(
        'La impresión Bluetooth funciona en la app de Android o iPhone. '
        'Aquí puedes compartir el documento como imagen.',
      );
    }
  }
}
