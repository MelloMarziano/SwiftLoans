import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../core/services/printer_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../documents/doc_frame.dart';
import '../../documents/document_actions.dart';
import '../widgets/settings_page.dart';

/// Preferencias de impresión y conexión con la impresora Bluetooth.
class PrinterSettingsView extends StatelessWidget {
  const PrinterSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Get.find<SettingsService>();

    return SettingsPage(
      title: 'Impresora',
      children: [
        Obx(
          () => SettingsGroup(
            title: 'Tipo de impresora',
            children: [
              for (final type in PrinterType.values)
                SettingsTile(
                  icon: switch (type) {
                    PrinterType.bluetooth => LucideIcons.bluetooth,
                    PrinterType.none => LucideIcons.ban,
                  },
                  title: type.label,
                  onTap: () => s.printerType.value = type,
                  trailing: _Check(selected: s.printerType.value == type),
                ),
            ],
          ),
        ),
        Obx(() {
          final enabled = s.printerType.value != PrinterType.none;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsGroup(
                    title: 'Recibo',
                    children: [
                      for (final width in PaperWidth.values)
                        SettingsTile(
                          icon: LucideIcons.ruler,
                          title: 'Papel de ${width.label}',
                          onTap: () => s.paperWidth.value = width,
                          trailing: _Check(
                            selected: s.paperWidth.value == width,
                          ),
                        ),
                      SettingsTile(
                        icon: LucideIcons.printer,
                        title: 'Imprimir al aplicar un pago',
                        subtitle: 'Imprime el recibo sin preguntar',
                        trailing: Switch(
                          value: s.autoPrint.value,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => s.autoPrint.value = v,
                        ),
                      ),
                      SettingsTile(
                        icon: LucideIcons.copy,
                        title: 'Copias por recibo',
                        trailing: _Stepper(
                          value: s.copies.value,
                          onChanged: (v) => s.copies.value = v,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SettingsGroup(
                    title: 'Conexión',
                    children: [
                      SettingsTile(
                        icon: LucideIcons.bluetooth,
                        title: s.printerName.value.isEmpty
                            ? 'Buscar impresoras'
                            : s.printerName.value,
                        subtitle: !PrinterService.isSupported
                            ? 'Disponible en la app de Android o iPhone'
                            : s.printerName.value.isEmpty
                            ? 'Ninguna impresora elegida'
                            : 'Toca para cambiar de impresora',
                        onTap: _PrinterPicker.show,
                      ),
                      SettingsTile(
                        icon: LucideIcons.receiptText,
                        title: 'Imprimir página de prueba',
                        onTap: () => DocumentActions.print(const _TestPage()),
                      ),
                      if (s.printerName.value.isNotEmpty)
                        SettingsTile(
                          icon: LucideIcons.unlink,
                          title: 'Olvidar impresora',
                          destructive: true,
                          onTap: Get.find<PrinterService>().forget,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: selected
          ? const Icon(
              LucideIcons.circleCheck,
              key: ValueKey(true),
              color: AppColors.primary,
            )
          : const Icon(
              LucideIcons.circle,
              key: ValueKey(false),
              color: AppColors.border,
            ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Menos',
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(LucideIcons.minus, size: 18),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        IconButton(
          tooltip: 'Más',
          onPressed: value < 3 ? () => onChanged(value + 1) : null,
          icon: const Icon(LucideIcons.plus, size: 18),
        ),
      ],
    );
  }
}

/// Lista de impresoras vinculadas en el Bluetooth del teléfono.
class _PrinterPicker extends StatefulWidget {
  const _PrinterPicker();

  static Future<void> show() async {
    if (!PrinterService.isSupported) {
      Get.snackbar(
        'Impresora Bluetooth',
        'La impresión funciona en la app de Android o iPhone. '
            'Aquí puedes compartir los documentos como imagen.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    await Get.bottomSheet(
      const _PrinterPicker(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<_PrinterPicker> createState() => _PrinterPickerState();
}

class _PrinterPickerState extends State<_PrinterPicker> {
  final _printer = Get.find<PrinterService>();
  List<BluetoothInfo>? _devices;
  String? _error;
  String? _connecting;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _devices = null;
      _error = null;
    });
    try {
      final list = await _printer.pairedPrinters();
      if (mounted) setState(() => _devices = list);
    } on PrinterFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _select(BluetoothInfo d) async {
    setState(() => _connecting = d.macAdress);
    try {
      await _printer.select(d);
      Get.back();
      Get.snackbar(
        'Impresora lista',
        d.name,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } on PrinterFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _connecting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = Get.find<SettingsService>().printerAddress.value;
    final devices = _devices;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Impresoras vinculadas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Buscar de nuevo',
                        onPressed: _load,
                        icon: const Icon(LucideIcons.refreshCw, size: 20),
                      ),
                    ],
                  ),
                  const Text(
                    'Primero vincula la impresora en el Bluetooth del teléfono '
                    '(suele pedir el PIN 0000 o 1234) y luego elígela aquí.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    )
                  else if (devices == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (devices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No hay dispositivos vinculados.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final d in devices)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.accentSoft,
                                child: Icon(
                                  LucideIcons.printer,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                d.name.isEmpty ? 'Sin nombre' : d.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(d.macAdress),
                              trailing: _connecting == d.macAdress
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : saved == d.macAdress
                                  ? const Icon(
                                      LucideIcons.circleCheck,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: _connecting == null
                                  ? () => _select(d)
                                  : null,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Página de prueba: confirma ancho del papel, tildes y la ñ.
class _TestPage extends StatelessWidget {
  const _TestPage();

  @override
  Widget build(BuildContext context) {
    final s = Get.find<SettingsService>();
    return DocFrame(
      title: 'Página de prueba',
      subtitle: 'Papel de ${s.paperWidth.value.label}',
      footer: 'Si lees bien las tildes y la ñ, todo está listo.',
      children: const [
        DocAmount(label: 'Monto de ejemplo', value: '1,234.56'),
        DocRow('Acentos', 'á é í ó ú ñ Ñ ¿? ¡!'),
        DocRow('Impresora', 'Bluetooth'),
        DocDivider(),
        DocRow('Total', '1,234.56', bold: true),
      ],
    );
  }
}
