import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Duraciones y curvas comunes para que todas las animaciones se sientan
/// iguales: rápidas y suaves, nunca estorban al cobrador.
abstract class Motion {
  static const fast = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 380);
  static const slow = Duration(milliseconds: 700);
  static const curve = Curves.easeOutCubic;
}

extension EntranceAnimation on Widget {
  /// Aparece desde abajo con un fundido. [index] escalona los elementos de
  /// una lista (solo los primeros, para no retrasar los que llegan al
  /// desplazarse).
  Widget entrance([int index = 0]) =>
      animate(delay: Duration(milliseconds: index < 10 ? index * 40 : 0))
          .fadeIn(duration: Motion.medium, curve: Motion.curve)
          .slideY(
            begin: 0.08,
            end: 0,
            duration: Motion.medium,
            curve: Motion.curve,
          );
}

/// Número que cuenta hasta su valor cuando cambia (montos, totales).
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.textAlign,
  });

  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: Motion.slow,
      curve: Motion.curve,
      builder: (_, v, _) => Text(format(v), style: style, textAlign: textAlign),
    );
  }
}

/// Barra de progreso que se llena con animación.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.value,
    required this.color,
    this.background = const Color(0xFFE8F0F2),
    this.height = 8,
  });

  final double value;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: Motion.slow,
        curve: Motion.curve,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: background,
          color: color,
        ),
      ),
    );
  }
}

/// Como [IndexedStack] (conserva el estado de cada pestaña), pero la pestaña
/// que entra aparece con un fundido y un leve deslizamiento.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Motion.fast,
    value: 1,
  );
  late final _fade = CurvedAnimation(parent: _controller, curve: Motion.curve);
  late final _slide = Tween(
    begin: const Offset(0, 0.015),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
    );
  }
}
