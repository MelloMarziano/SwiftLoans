import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Montos con separador de miles y hasta 2 decimales: "10,450.50".
class MoneyInputFormatter extends TextInputFormatter {
  static final _format = NumberFormat('#,##0', 'en_US');
  static final _valid = RegExp(r'^\d{0,12}(\.\d{0,2})?$');

  /// "10,450.50" -> 10450.5
  static double parse(String text) =>
      double.tryParse(text.replaceAll(',', '')) ?? 0;

  /// 10450.5 -> "10,450.50"
  static String format(double value) =>
      NumberFormat('#,##0.00', 'en_US').format(value);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    if (!_valid.hasMatch(raw)) return oldValue;

    final parts = raw.split('.');
    final whole = _format.format(int.parse(parts[0].isEmpty ? '0' : parts[0]));
    final text = parts.length > 1 ? '$whole.${parts[1]}' : whole;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Decimales simples (tasas, porcentajes): hasta 3 enteros y 2 decimales.
class DecimalInputFormatter extends TextInputFormatter {
  static final _valid = RegExp(r'^\d{0,3}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _valid.hasMatch(newValue.text) ? newValue : oldValue;
}

/// Aplica una máscara de dígitos, p. ej. "###-#######-#" para la cédula.
class MaskedDigitsFormatter extends TextInputFormatter {
  MaskedDigitsFormatter(this.mask) : _maxDigits = '#'.allMatches(mask).length;

  /// Cédula dominicana: 001-1234567-8
  factory MaskedDigitsFormatter.cedula() =>
      MaskedDigitsFormatter('###-#######-#');

  /// Teléfono: 809-555-1234
  factory MaskedDigitsFormatter.phone() =>
      MaskedDigitsFormatter('###-###-####');

  final String mask;
  final int _maxDigits;

  /// Cantidad de dígitos que exige la máscara (11 cédula, 10 teléfono).
  int get maxDigits => _maxDigits;

  static String digitsOf(String text) => text.replaceAll(RegExp(r'\D'), '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = digitsOf(newValue.text);
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);

    final buffer = StringBuffer();
    var d = 0;
    for (var i = 0; i < mask.length && d < digits.length; i++) {
      if (mask[i] == '#') {
        buffer.write(digits[d++]);
      } else {
        buffer.write(mask[i]);
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
