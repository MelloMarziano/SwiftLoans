import 'package:flutter/material.dart';

/// Contenedor desplazable que limita el ancho del contenido en pantallas grandes
/// y deja espacio para la barra inferior flotante en móvil.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.children,
    this.maxWidth = 1200,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600 ? 14.0 : 32.0;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          width < 600 ? 14 : 24,
          horizontal,
          width < 600 ? 120 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
