import 'package:flutter/widgets.dart';

extension ResponsiveContext on BuildContext {
  /// Pantallas angostas (teléfonos y handhelds).
  bool get isCompact => MediaQuery.sizeOf(this).width < 600;

  /// Devuelve [compact] en teléfonos y [regular] en tablet/web.
  double sized(double compact, double regular) => isCompact ? compact : regular;
}
