import 'package:intl/intl.dart';

abstract class Formatters {
  static final _currency = NumberFormat('#,##0', 'en_US');
  static final _currency2 = NumberFormat('#,##0.00', 'en_US');

  /// 10450000 -> "10,450,000"
  static String currency(num value) => _currency.format(value);

  /// 4500.5 -> "4,500.50" (con centavos, para cuotas y montos exactos)
  static String currency2(num value) => _currency2.format(value);

  /// 800000 -> "800K", 1200000 -> "1.2M"
  static String compact(num value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }

  /// 0.845 -> "84.5%"
  static String percent(double ratio) => '${(ratio * 100).toStringAsFixed(1)}%';
}
