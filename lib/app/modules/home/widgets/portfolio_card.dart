import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/trend_badge.dart';
import '../home_controller.dart';

/// Tarjeta destacada con el total de la cartera activa.
class PortfolioCard extends GetView<HomeController> {
  const PortfolioCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En móvil el badge sube junto a la etiqueta para que el monto no se encoja.
        final compact = constraints.maxWidth < 520;
        final iconSize = compact ? 44.0 : 64.0;

        final amount = Obx(
          () => Text(
            Formatters.currency(controller.activePortfolio.value),
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 21 : 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
        final badge = Obx(() {
          final growth = controller.portfolioGrowth.value;
          if (growth == null) return const SizedBox.shrink();
          return TrendBadge(
            label: '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
            tone: TrendTone.onDark,
            up: growth >= 0,
          );
        });
        final label = Text(
          'Cartera activa',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w500,
          ),
        );

        return Container(
          height: compact ? 104 : 124,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                width: compact ? constraints.maxWidth * 0.42 : 220,
                height: compact ? 56 : 108,
                child: const CustomPaint(painter: _SparklinePainter()),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 22),
                child: Row(
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        LucideIcons.layers,
                        color: Colors.white,
                        size: iconSize / 2,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 52,
                      margin: EdgeInsets.symmetric(
                        horizontal: compact ? 14 : 18,
                      ),
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: compact
                            ? [
                                Row(
                                  children: [
                                    Flexible(child: label),
                                    const SizedBox(width: 8),
                                    badge,
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: amount,
                                ),
                              ]
                            : [
                                label,
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(child: amount),
                                    const SizedBox(width: 12),
                                    badge,
                                  ],
                                ),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter();

  static const _points = [0.95, 0.9, 0.72, 0.5, 0.48, 0.35, 0.2, 0.12];

  @override
  void paint(Canvas canvas, Size size) {
    final dx = size.width / (_points.length - 1);
    final offsets = [
      for (var i = 0; i < _points.length; i++)
        Offset(i * dx, _points[i] * size.height),
    ];

    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      final prev = offsets[i - 1];
      final curr = offsets[i];
      final midX = (prev.dx + curr.dx) / 2;
      line.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accent.withValues(alpha: 0.35),
            AppColors.accent.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final dot = Paint()..color = AppColors.accentSoft;
    for (final i in [2, 4, 7]) {
      canvas.drawCircle(offsets[i], 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
