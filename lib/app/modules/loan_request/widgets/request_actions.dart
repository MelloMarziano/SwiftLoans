import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../loan_request_controller.dart';

/// "Listado de cuotas" + botón "Guardar solicitud".
class RequestActions extends GetView<LoanRequestController> {
  const RequestActions({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.sized(18, 20));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.tile,
          borderRadius: radius,
          child: InkWell(
            onTap: controller.openSchedule,
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsets.all(context.sized(14, 18)),
              child: Row(
                children: [
                  Container(
                    width: context.sized(38, 44),
                    height: context.sized(38, 44),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.list,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      final quote = controller.quote.value;
                      final subtitle = quote.schedule.isEmpty
                          ? 'Ingresa el monto para ver las cuotas'
                          : '${quote.schedule.length} cuotas · Total '
                                '${Formatters.currency2(quote.totalPayment)}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listado de cuotas',
                            style: TextStyle(
                              fontSize: context.sized(16, 17),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: context.sized(12, 13),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: context.sized(16, 20)),
        Obx(() {
          final saving = controller.isSaving.value;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: saving ? null : controller.save,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                shadowColor: Colors.transparent,
                minimumSize: Size.fromHeight(context.sized(52, 58)),
                shape: const StadiumBorder(),
                textStyle: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: context.sized(16, 17),
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.save, size: 22),
              label: Text(saving ? 'Guardando...' : 'Guardar solicitud'),
            ),
          );
        }),
      ],
    );
  }
}
