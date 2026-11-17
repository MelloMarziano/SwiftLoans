import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/printer_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import 'doc_frame.dart';

/// Convierte un documento en imagen para compartirlo (WhatsApp, correo...)
/// o imprimirlo en la impresora Bluetooth.
abstract class DocumentActions {
  /// Dibuja [doc] fuera de pantalla y devuelve el PNG.
  static Future<Uint8List> render(Widget doc, {required bool forPrint}) async {
    final context = Get.context;
    if (context != null && !forPrint) {
      await precacheImage(const AssetImage(BrandAssets.horizontal), context);
    }
    final ratio = forPrint
        ? Get.find<SettingsService>().paperWidth.value.dots / docWidth
        : 3.0;
    return ScreenshotController().captureFromLongWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.white,
            child: DocStyle(forPrint: forPrint, child: doc),
          ),
        ),
      ),
      pixelRatio: ratio,
      delay: const Duration(milliseconds: 60),
      constraints: const BoxConstraints(maxWidth: docWidth),
    );
  }

  /// Abre el menú de compartir del sistema con la imagen (en web la
  /// descarga si el navegador no permite compartir archivos).
  static Future<void> share(
    Widget doc, {
    required String fileName,
    String? text,
  }) async {
    try {
      final png = await render(doc, forPrint: false);
      final name = '$fileName.png';
      final size = Get.size;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
          fileNameOverrides: [name],
          text: text,
          // Necesario en iPad: desde dónde sale el menú.
          sharePositionOrigin: Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 1,
            height: 1,
          ),
        ),
      );
    } catch (e) {
      _error('No se pudo compartir', '$e');
    }
  }

  /// Imprime en la impresora Bluetooth. Devuelve true si se imprimió.
  static Future<bool> print(Widget doc, {bool quiet = false}) async {
    final printer = Get.find<PrinterService>();
    try {
      final png = await render(doc, forPrint: true);
      await printer.printPng(png);
      if (!quiet) {
        Get.snackbar(
          'Enviado a la impresora',
          printer.printerName,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
        );
      }
      return true;
    } on PrinterFailure catch (e) {
      _error('No se pudo imprimir', e.message);
    } catch (e) {
      _error('No se pudo imprimir', '$e');
    }
    return false;
  }

  static void _error(String title, String message) => Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(16),
  );
}

/// Vista previa del documento con los botones Compartir e Imprimir.
class DocumentSheet extends StatefulWidget {
  const DocumentSheet({
    super.key,
    required this.title,
    required this.document,
    required this.fileName,
    this.shareText,
    this.extraAction,
  });

  final String title;
  final Widget Function() document;
  final String fileName;
  final String? shareText;

  /// Botón adicional sobre Compartir/Imprimir (p. ej. "Marcar revisado").
  final Widget? extraAction;

  static Future<void> show({
    required String title,
    required Widget Function() document,
    required String fileName,
    String? shareText,
    Widget? extraAction,
  }) => Get.bottomSheet(
    DocumentSheet(
      title: title,
      document: document,
      fileName: fileName,
      shareText: shareText,
      extraAction: extraAction,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );

  @override
  State<DocumentSheet> createState() => _DocumentSheetState();
}

class _DocumentSheetState extends State<DocumentSheet> {
  var _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    await DocumentActions.share(
      widget.document(),
      fileName: widget.fileName,
      text: widget.shareText,
    );
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final printer = Get.find<PrinterService>();

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: DocStyle(
                              forPrint: false,
                              child: widget.document(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.extraAction != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: widget.extraAction,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _sharing ? null : _share,
                          icon: _sharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(LucideIcons.share2, size: 20),
                          label: const Text('Compartir'),
                          style: _style(filled: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(
                          () => OutlinedButton.icon(
                            onPressed: printer.isPrinting.value
                                ? null
                                : () =>
                                      DocumentActions.print(widget.document()),
                            icon: printer.isPrinting.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(LucideIcons.printer, size: 20),
                            label: const Text('Imprimir'),
                            style: _style(filled: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static ButtonStyle _style({required bool filled}) {
    final base = filled
        ? FilledButton.styleFrom(backgroundColor: AppColors.primary)
        : OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            backgroundColor: AppColors.surface,
          );
    return base.copyWith(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
