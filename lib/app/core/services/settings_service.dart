import 'package:get/get.dart';

import '../../data/catalogs.dart';
import '../../data/models/loan_terms.dart';
import 'key_value_store.dart';

enum PrinterType {
  bluetooth('Impresora Bluetooth'),
  none('Sin impresora');

  const PrinterType(this.label);
  final String label;
}

enum PaperWidth {
  mm58('58 mm', 384),
  mm80('80 mm', 576);

  const PaperWidth(this.label, this.dots);
  final String label;

  /// Puntos que imprime la cabeza térmica por línea.
  final int dots;
}

/// Ajustes de la app.
///
/// - Empresa (negocio, préstamos por defecto, rutas): iguales para todos los
///   usuarios de la empresa; se guardan en la base de datos.
/// - Dispositivo (impresora): propios de cada teléfono.
class SettingsService extends GetxService {
  SettingsService({required KeyValueStore store}) : _store = store;

  final KeyValueStore _store;

  /// Almacenamiento local del teléfono (lo comparten otros servicios).
  KeyValueStore get store => _store;

  // Negocio (aparece en el recibo)
  final businessName = 'SwiftLoans'.obs;
  final businessRnc = ''.obs;
  final businessPhone = ''.obs;
  final businessAddress = ''.obs;
  final receiptFooter = 'Gracias por su pago'.obs;

  // Valores por defecto de una nueva solicitud
  final defaultRate = 20.0.obs;
  final defaultLateFee = 5.0.obs;
  final defaultFrequency = PaymentFrequency.daily.obs;
  final defaultType = LoanType.interestAndCapital.obs;
  final defaultInstallments = 30.obs;
  final defaultClosingCost = 0.0.obs;

  // Rutas de cobro y oficinas
  final routes = <String>[...Catalogs.routes].obs;

  // Impresora
  final printerType = PrinterType.bluetooth.obs;
  final paperWidth = PaperWidth.mm58.obs;
  final autoPrint = false.obs;
  final copies = 1.obs;

  /// Impresora Bluetooth vinculada (vacío = ninguna).
  final printerName = ''.obs;
  final printerAddress = ''.obs;

  /// Se llama (con una pausa) cuando cambia un ajuste de la empresa, para
  /// guardarlo en la base de datos. Lo conecta [CompanySettingsSync].
  void Function(Map<String, dynamic> settings)? onCompanyChanged;

  /// Ajustes de empresa que quedaron guardados en este teléfono de versiones
  /// anteriores; se suben una vez si la empresa aún no tiene los suyos.
  Map<String, dynamic>? legacyCompany;

  var _applying = false;
  final _companyDirty = 0.obs;

  static const _legacyKeys = {
    'name': 'business.name',
    'rnc': 'business.rnc',
    'phone': 'business.phone',
    'address': 'business.address',
    'footer': 'business.footer',
    'rate': 'loan.rate',
    'lateFee': 'loan.lateFee',
    'frequency': 'loan.frequency',
    'type': 'loan.type',
    'installments': 'loan.installments',
    'closingCost': 'loan.closingCost',
    'routes': 'routes',
  };

  @override
  void onInit() {
    super.onInit();
    // Empresa: se guardan en la base de datos (ver CompanySettingsSync).
    final legacy = <String, dynamic>{
      for (final e in _legacyKeys.entries)
        if (_store.read<dynamic>(e.value) != null)
          e.key: _store.read<dynamic>(e.value),
    };
    if (legacy.isNotEmpty) legacyCompany = legacy;

    everAll(
      [
        businessName,
        businessRnc,
        businessPhone,
        businessAddress,
        receiptFooter,
        defaultRate,
        defaultLateFee,
        defaultFrequency,
        defaultType,
        defaultInstallments,
        defaultClosingCost,
        routes,
      ],
      (_) {
        if (!_applying) _companyDirty.value++;
      },
    );
    debounce(
      _companyDirty,
      (_) => onCompanyChanged?.call(companyMap()),
      time: const Duration(milliseconds: 400),
    );

    // Dispositivo: se quedan en este teléfono.
    _bindEnum(printerType, 'printer.type', PrinterType.values);
    _bindEnum(paperWidth, 'printer.paper', PaperWidth.values);
    _bind(autoPrint, 'printer.autoPrint');
    _bind(copies, 'printer.copies');
    _bind(printerName, 'printer.name');
    _bind(printerAddress, 'printer.address');
  }

  /// Ajustes de la empresa para guardarlos.
  Map<String, dynamic> companyMap() => {
    'name': businessName.value,
    'rnc': businessRnc.value,
    'phone': businessPhone.value,
    'address': businessAddress.value,
    'footer': receiptFooter.value,
    'rate': defaultRate.value,
    'lateFee': defaultLateFee.value,
    'frequency': defaultFrequency.value.name,
    'type': defaultType.value.name,
    'installments': defaultInstallments.value,
    'closingCost': defaultClosingCost.value,
    'routes': routes.toList(),
  };

  /// Carga los ajustes de la empresa (null = valores de fábrica) sin
  /// volver a guardarlos.
  void applyCompany(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    _applying = true;
    try {
      businessName.value = d['name'] as String? ?? 'SwiftLoans';
      businessRnc.value = d['rnc'] as String? ?? '';
      businessPhone.value = d['phone'] as String? ?? '';
      businessAddress.value = d['address'] as String? ?? '';
      receiptFooter.value = d['footer'] as String? ?? 'Gracias por su pago';
      defaultRate.value = (d['rate'] as num?)?.toDouble() ?? 20;
      defaultLateFee.value = (d['lateFee'] as num?)?.toDouble() ?? 5;
      defaultFrequency.value =
          PaymentFrequency.values.asNameMap()[d['frequency']] ??
          PaymentFrequency.daily;
      defaultType.value =
          LoanType.values.asNameMap()[d['type']] ?? LoanType.interestAndCapital;
      defaultInstallments.value = (d['installments'] as num?)?.toInt() ?? 30;
      defaultClosingCost.value = (d['closingCost'] as num?)?.toDouble() ?? 0;
      final saved = (d['routes'] as List?)?.cast<String>();
      routes.assignAll(
        saved == null || saved.isEmpty ? Catalogs.routes : saved,
      );
    } finally {
      _applying = false;
    }
  }

  /// Ya se subieron los ajustes viejos de este teléfono.
  void clearLegacyCompany() {
    legacyCompany = null;
    for (final key in _legacyKeys.values) {
      _store.remove(key);
    }
  }

  /// Ajustes de la empresa a los de fábrica (se guarda para todos).
  void resetCompany() {
    applyCompany(null);
    _companyDirty.value++;
  }

  /// Impresora de este teléfono a los valores de fábrica.
  void resetDevice() {
    for (final key in [
      'printer.type',
      'printer.paper',
      'printer.autoPrint',
      'printer.copies',
      'printer.name',
      'printer.address',
    ]) {
      _store.remove(key);
    }
    printerType.value = PrinterType.bluetooth;
    paperWidth.value = PaperWidth.mm58;
    autoPrint.value = false;
    copies.value = 1;
    printerName.value = '';
    printerAddress.value = '';
  }

  void _bind<T>(Rx<T> rx, String key) {
    final saved = _store.read<T>(key);
    if (saved != null) rx.value = saved;
    ever(rx, (value) => _store.write(key, value));
  }

  void _bindEnum<T extends Enum>(Rx<T> rx, String key, List<T> values) {
    final saved = _store.read<String>(key);
    final match = values.where((v) => v.name == saved);
    if (match.isNotEmpty) rx.value = match.first;
    ever(rx, (value) => _store.write(key, value.name));
  }
}
