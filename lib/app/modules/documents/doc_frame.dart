import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/services/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';

/// Cómo se dibuja un documento: a color para compartir (WhatsApp) o en
/// blanco y negro, con letra más grande, para la impresora térmica.
class DocStyle extends InheritedWidget {
  const DocStyle({super.key, required this.forPrint, required super.child});

  final bool forPrint;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocStyle>()?.forPrint ?? false;

  @override
  bool updateShouldNotify(DocStyle old) => old.forPrint != forPrint;
}

/// Ancho lógico de todos los documentos. La imagen final se escala al ancho
/// del papel (58/80 mm) o a alta resolución para compartir.
const docWidth = 360.0;

/// Colores del documento según el modo.
class DocColors {
  const DocColors._(this.print);

  factory DocColors.of(BuildContext context) =>
      DocColors._(DocStyle.of(context));

  final bool print;

  Color get text => print ? Colors.black : AppColors.textPrimary;
  Color get muted => print ? Colors.black : AppColors.textSecondary;
  Color get accent => print ? Colors.black : AppColors.primary;
  Color get positive => print ? Colors.black : AppColors.success;
  Color get negative => print ? Colors.black : AppColors.danger;
  Color get line => print ? Colors.black : AppColors.border;
  Color get soft => print ? Colors.white : AppColors.background;
}

/// Encabezado con el negocio, título del documento, contenido y pie con la
/// fecha de emisión.
class DocFrame extends StatelessWidget {
  const DocFrame({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Texto final (p. ej. "Gracias por su pago").
  final String? footer;

  static final _issued = DateFormat('dd/MM/yyyy h:mm a');

  @override
  Widget build(BuildContext context) {
    final c = DocColors.of(context);
    final s = Get.find<SettingsService>();
    final business = [
      if (s.businessRnc.value.isNotEmpty) 'RNC: ${s.businessRnc.value}',
      if (s.businessPhone.value.isNotEmpty) 'Tel.: ${s.businessPhone.value}',
      if (s.businessAddress.value.isNotEmpty) s.businessAddress.value,
    ];

    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: c.text,
        fontSize: c.print ? 17 : 14,
        fontWeight: c.print ? FontWeight.w600 : FontWeight.w500,
        height: 1.3,
      ),
      child: Container(
        width: docWidth,
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          c.print ? 4 : 22,
          c.print ? 8 : 22,
          c.print ? 4 : 22,
          c.print ? 8 : 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!c.print) ...[
              const Center(child: BrandWordmark(height: 40)),
              const SizedBox(height: 8),
            ],
            Text(
              s.businessName.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: c.print ? 22 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final line in business)
              Text(
                line,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: c.print ? 16 : 12.5),
              ),
            SizedBox(height: c.print ? 8 : 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: c.print ? Colors.black : AppColors.primaryDark,
                borderRadius: BorderRadius.circular(c.print ? 0 : 12),
              ),
              child: Column(
                children: [
                  Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: c.print ? 19 : 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: c.print ? 15 : 12.5,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: c.print ? 6 : 12),
            ...children,
            if (footer != null && footer!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                footer!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontStyle: FontStyle.italic),
              ),
            ],
            SizedBox(height: c.print ? 10 : 14),
            Text(
              'Emitido ${_issued.format(DateTime.now())} · SwiftLoans',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: c.print ? 14 : 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila "etiqueta ........ valor".
class DocRow extends StatelessWidget {
  const DocRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.color,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = DocColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.muted)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : null,
                color: c.print ? null : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monto grande destacado (p. ej. el total pagado).
class DocAmount extends StatelessWidget {
  const DocAmount({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = DocColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: c.print
            ? null
            : (color ?? AppColors.primary).withValues(alpha: 0.08),
        border: c.print ? Border.all(width: 2) : null,
        borderRadius: BorderRadius.circular(c.print ? 0 : 14),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: c.muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: c.print ? 30 : 26,
              fontWeight: FontWeight.w800,
              color: c.print ? Colors.black : (color ?? AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección dentro del documento.
class DocSection extends StatelessWidget {
  const DocSection(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = DocColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w800, color: c.accent),
      ),
    );
  }
}

/// Línea punteada separadora.
class DocDivider extends StatelessWidget {
  const DocDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DocColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: List.generate(
          36,
          (_) => Expanded(
            child: Container(
              height: c.print ? 1.5 : 1,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              color: c.line,
            ),
          ),
        ),
      ),
    );
  }
}
