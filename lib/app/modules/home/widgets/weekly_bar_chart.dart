import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../home_controller.dart';

/// Gráfico de barras agrupadas (cobros / desembolsos) por día.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.data,
    required this.onSelect,
    this.selected,
    this.height = 150,
    this.steps = 4,
  });

  final List<DailyFlow> data;
  final ValueChanged<int> onSelect;
  final int? selected;
  final double height;
  final int steps;

  /// Redondea el máximo hacia arriba a un múltiplo de 200K por línea de guía.
  /// Tope del eje: el monto más alto redondeado a un paso "bonito"
  /// (1, 2, 2.5 o 5 × 10^n por línea), para que las barras se vean igual de
  /// bien con 600 que con 600,000.
  double get _maxValue {
    final peak = data.fold<double>(
      0,
      (m, d) => math.max(m, math.max(d.collections, d.disbursements)),
    );
    if (peak <= 0) return 1000.0 * steps;
    final raw = peak / steps;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final step = [
      1,
      2,
      2.5,
      5,
      10,
    ].map((f) => f * magnitude).firstWhere((s) => s >= raw);
    return step * steps;
  }

  @override
  Widget build(BuildContext context) {
    final max = _maxValue;
    const labelStyle = TextStyle(color: AppColors.textSecondary, fontSize: 12);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eje Y
        SizedBox(
          width: 42,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i <= steps; i++)
                Positioned(
                  left: 0,
                  top: height - height * i / steps - 8,
                  child: Text(
                    Formatters.compact(max * i / steps),
                    style: labelStyle,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPainter(steps: steps)),
                    ),
                    // Positioned.fill: sin esto el Stack alinea las barras
                    // arriba y las bajas quedan "flotando".
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final groupWidth = constraints.maxWidth / data.length;
                          final barWidth = math.min(16.0, groupWidth * 0.32);
                          final gap = math.min(4.0, groupWidth * 0.06);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < data.length; i++)
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => onSelect(i),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      opacity: selected == null || selected == i
                                          ? 1
                                          : 0.35,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          _Bar(
                                            width: barWidth,
                                            height:
                                                height *
                                                data[i].collections /
                                                max,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: gap),
                                          _Bar(
                                            width: barWidth,
                                            height:
                                                height *
                                                data[i].disbursements /
                                                max,
                                            color: AppColors.accent,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < data.length; i++)
                    Expanded(
                      child: Text(
                        data[i].day,
                        textAlign: TextAlign.center,
                        style: labelStyle.copyWith(
                          color: selected == i
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: selected == i
                              ? FontWeight.w800
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.4)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.steps});

  final int steps;

  @override
  void paint(Canvas canvas, Size size) {
    final dashed = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;

    for (var i = 1; i <= steps; i++) {
      final y = size.height - size.height * i / steps;
      for (double x = 0; x < size.width; x += dash + gap) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + dash, size.width), y),
          dashed,
        );
      }
    }

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = const Color(0xFFCFDDE0)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.steps != steps;
}
