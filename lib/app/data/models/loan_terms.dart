/// Frecuencia de pago de las cuotas.
enum PaymentFrequency {
  daily('Diario', 'días', 'diarias', 30),
  weekly('Semanal', 'semanas', 'semanales', 4),
  biweekly('Quincenal', 'quincenas', 'quincenales', 2),
  monthly('Mensual', 'meses', 'mensuales', 1);

  const PaymentFrequency(
    this.label,
    this.periodName,
    this.installmentsAdjective,
    this.periodsPerMonth,
  );

  final String label;

  /// Para "30 cuotas diarias", "12 cuotas semanales"...
  final String installmentsAdjective;

  /// Nombre del periodo en plural, para "No. de días", "No. de semanas"...
  final String periodName;

  /// Cuántos periodos tiene un mes; se usa para prorratear la tasa mensual.
  final int periodsPerMonth;

  /// Fecha de la cuota [number] (1 = primera) contando desde [start].
  DateTime dueDate(DateTime start, int number) => switch (this) {
    daily => DateTime(start.year, start.month, start.day + number),
    weekly => DateTime(start.year, start.month, start.day + 7 * number),
    biweekly => DateTime(start.year, start.month, start.day + 15 * number),
    monthly => _addMonths(start, number),
  };

  static DateTime _addMonths(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(target.year, target.month, date.day.clamp(1, lastDay));
  }
}

/// Forma en que se calcula la cuota.
enum LoanType {
  /// Interés fijo sobre el monto original: cada cuota = capital/n + interés.
  interestAndCapital('Interés y capital'),

  /// Cada cuota es solo interés; el capital se paga con la última cuota.
  interestOnly('Solo interés'),

  /// Cuota fija con interés sobre el saldo (sistema francés).
  amortized('Cuota fija (amortizado)');

  const LoanType(this.label);
  final String label;
}

class Installment {
  const Installment({
    required this.number,
    required this.dueDate,
    required this.capital,
    required this.interest,
    required this.balance,
  });

  final int number;
  final DateTime dueDate;
  final double capital;
  final double interest;

  /// Saldo de capital después de pagar esta cuota.
  final double balance;

  double get payment => capital + interest;
}
