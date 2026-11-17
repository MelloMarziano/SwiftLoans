import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Periodos de consulta (Movimientos, Gastos...).
enum DatePeriod {
  today('Hoy'),
  yesterday('Ayer'),
  week('Esta semana'),
  month('Este mes'),
  custom('Rango');

  const DatePeriod(this.label);
  final String label;

  /// Inicio (incluido) y fin (excluido) del periodo a la fecha [now].
  /// La semana va de lunes a hoy; [custom] usa [customRange] (o hoy).
  (DateTime, DateTime) range(DateTime now, [DateTimeRange? customRange]) {
    final day = DateTime(now.year, now.month, now.day);
    final tomorrow = day.add(const Duration(days: 1));
    return switch (this) {
      today => (day, tomorrow),
      yesterday => (day.subtract(const Duration(days: 1)), day),
      week => (day.subtract(Duration(days: day.weekday - 1)), tomorrow),
      month => (DateTime(day.year, day.month), tomorrow),
      custom =>
        customRange == null
            ? (day, tomorrow)
            : (
                DateTime(
                  customRange.start.year,
                  customRange.start.month,
                  customRange.start.day,
                ),
                DateTime(
                  customRange.end.year,
                  customRange.end.month,
                  customRange.end.day + 1,
                ),
              ),
    };
  }

  /// Texto del periodo para documentos: "Hoy: 16/11/2026",
  /// "Este mes: 01/11/2026 – 16/11/2026".
  String describe(DateTime now, [DateTimeRange? customRange]) {
    final f = DateFormat('dd/MM/yyyy');
    final (from, to) = range(now, customRange);
    final last = to.subtract(const Duration(days: 1));
    final dates = from == last
        ? f.format(from)
        : '${f.format(from)} – ${f.format(last)}';
    return this == custom ? dates : '$label: $dates';
  }

  bool contains(DateTime date, DateTime now, [DateTimeRange? customRange]) {
    final (from, to) = range(now, customRange);
    return !date.isBefore(from) && date.isBefore(to);
  }
}
