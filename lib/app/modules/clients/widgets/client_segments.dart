import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../clients_controller.dart';

/// Pestañas: Todos / Con préstamo / Sin préstamo.
class ClientSegments extends GetView<ClientsController> {
  const ClientSegments({super.key});

  static const _labels = {
    ClientSegment.all: 'Todos',
    ClientSegment.withLoan: 'Con préstamo',
    ClientSegment.withoutLoan: 'Sin préstamo',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Obx(
        () => Row(
          children: [
            for (final segment in ClientSegment.values)
              Expanded(
                child: _Segment(
                  label:
                      '${_labels[segment]} (${controller.countFor(segment)})',
                  selected: controller.segment.value == segment,
                  onTap: () => controller.changeSegment(segment),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: context.sized(38, 44),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: context.sized(13, 15),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
