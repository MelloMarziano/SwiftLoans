import 'package:flutter/material.dart';

abstract class BrandAssets {
  static const icon = 'assets/logo_icon.png';
  static const horizontal = 'assets/logo_horizontal.png';
}

/// Ícono cuadrado de la marca.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.icon,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'SwiftLoans',
    );
  }
}

/// Logo completo: ícono + "SwiftLoans" + "Gestión de Préstamos".
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.height = 52});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.horizontal,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'SwiftLoans, gestión de préstamos',
    );
  }
}
