import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/motion.dart';
import '../../data/models/app_user.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/brand_logo.dart';
import 'login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _LoginBackground()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children:
                          [
                                Center(
                                  child:
                                      BrandWordmark(
                                        height: context.sized(76, 92),
                                      ).animate().scale(
                                        begin: const Offset(0.85, 0.85),
                                        duration: Motion.slow,
                                        curve: Curves.easeOutBack,
                                      ),
                                ),
                                SizedBox(height: context.sized(32, 40)),
                                Text(
                                  'Bienvenido de nuevo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: context.sized(26, 30),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ingresa a tu cuenta para continuar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: context.sized(14, 16),
                                  ),
                                ),
                                SizedBox(height: context.sized(28, 32)),
                                _LoginField(
                                  icon: LucideIcons.user,
                                  hint: 'Usuario o correo',
                                  controller: controller.identifier,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.username],
                                  onSubmitted: (_) =>
                                      controller.passwordFocus.requestFocus(),
                                ),
                                const SizedBox(height: 14),
                                Obx(
                                  () => _LoginField(
                                    icon: LucideIcons.lock,
                                    hint: 'Contraseña',
                                    controller: controller.password,
                                    focusNode: controller.passwordFocus,
                                    obscure: controller.obscure.value,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => controller.signIn(),
                                    trailing: IconButton(
                                      tooltip: controller.obscure.value
                                          ? 'Mostrar contraseña'
                                          : 'Ocultar contraseña',
                                      onPressed: controller.obscure.toggle,
                                      icon: Icon(
                                        controller.obscure.value
                                            ? LucideIcons.eyeOff
                                            : LucideIcons.eye,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Obx(
                                      () => Checkbox(
                                        value: controller.remember.value,
                                        onChanged: (v) =>
                                            controller.remember.value =
                                                v ?? true,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: controller.remember.toggle,
                                      child: const Text(
                                        'Recordarme',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: controller.forgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                      ),
                                      child: const Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Obx(
                                  () => AnimatedSize(
                                    duration: const Duration(milliseconds: 200),
                                    child: controller.error.value == null
                                        ? const SizedBox(width: double.infinity)
                                        : _ErrorBanner(
                                            message: controller.error.value!,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Obx(
                                  () => _PrimaryButton(
                                    loading: controller.isLoading.value,
                                    onPressed: controller.signIn,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const _DemoButton(),
                              ]
                              .animate(interval: 60.ms)
                              .fadeIn(
                                duration: Motion.medium,
                                curve: Motion.curve,
                              )
                              .slideY(begin: 0.12, curve: Motion.curve),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.icon,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 21, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscure,
              keyboardType: keyboardType,
              autofillHints: autofillHints,
              autocorrect: false,
              enableSuggestions: !obscure,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 18,
            color: AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(LucideIcons.logIn, size: 22),
        label: Text(loading ? 'Entrando...' : 'Iniciar sesión'),
      ),
    );
  }
}

/// Ondas y barras decorativas del fondo, como en el diseño.
class _LoginBackground extends CustomPainter {
  const _LoginBackground();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Onda superior derecha
    final topRight = Path()
      ..moveTo(w * 0.55, 0)
      ..cubicTo(w * 0.7, h * 0.06, w * 0.85, h * 0.02, w, h * 0.11)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(
      topRight,
      Paint()..color = AppColors.accent.withValues(alpha: 0.35),
    );

    // Onda superior izquierda, muy suave
    final topLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.45, 0)
      ..cubicTo(w * 0.3, h * 0.08, w * 0.12, h * 0.1, 0, h * 0.16)
      ..close();
    canvas.drawPath(
      topLeft,
      Paint()..color = AppColors.accent.withValues(alpha: 0.12),
    );

    // Barras de crecimiento (solo si hay espacio)
    if (h > 720) {
      final barPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35);
      final barWidth = w * 0.045 < 22 ? w * 0.045 : 22.0;
      // 4 barras con separación de 0.6 del ancho, centradas.
      final baseX = (w - barWidth * (4 + 3 * 0.6)) / 2;
      for (var i = 0; i < 4; i++) {
        final barHeight = h * (0.035 + i * 0.03);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              baseX + i * barWidth * 1.6,
              h * 0.96 - barHeight,
              barWidth,
              barHeight,
            ),
            topLeft: const Radius.circular(5),
            topRight: const Radius.circular(5),
          ),
          barPaint,
        );
      }
    }

    // Ondas inferiores en capas
    void wave(double startY, double peakY, Color color) {
      final path = Path()
        ..moveTo(0, h * startY)
        ..cubicTo(
          w * 0.3,
          h * (startY - 0.02),
          w * 0.65,
          h * peakY,
          w,
          h * (peakY - 0.03),
        )
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    wave(0.9, 0.94, AppColors.accent.withValues(alpha: 0.3));
    wave(0.95, 0.97, AppColors.primary.withValues(alpha: 0.55));
    wave(0.98, 0.99, AppColors.primaryDark.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "¿Quieres conocer la app? Ver demo": entra sin cuenta con datos de
/// ejemplo, como dueño o como cobrador.
class _DemoButton extends GetView<LoginController> {
  const _DemoButton();

  Future<void> _choose() async {
    final user = await Get.bottomSheet<AppUser>(
      const _DemoSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (user != null) controller.startDemo(user);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '¿Quieres conocer la app?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 14),
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _choose,
            icon: const Icon(LucideIcons.playCircle, size: 20),
            label: const Text('Ver demo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size.fromHeight(50),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoSheet extends StatelessWidget {
  const _DemoSheet();

  @override
  Widget build(BuildContext context) {
    Widget option({
      required IconData icon,
      required String title,
      required String subtitle,
      required AppUser user,
    }) => Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Get.back(result: user),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Prueba SwiftLoans',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Entra con datos de ejemplo. Puedes cobrar, prestar e '
                    'imprimir; nada se guarda y al salir vuelve a empezar.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  option(
                    icon: LucideIcons.briefcaseBusiness,
                    title: 'Como dueño',
                    subtitle: 'Cartera, reportes, equipo y cuadres',
                    user: DemoMode.owner,
                  ),
                  const SizedBox(height: 10),
                  option(
                    icon: LucideIcons.bike,
                    title: 'Como cobrador',
                    subtitle: 'Cobrar en ruta, recibos y cuadre del día',
                    user: DemoMode.collector,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
