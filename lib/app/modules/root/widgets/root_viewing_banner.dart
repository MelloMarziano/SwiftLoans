import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/company_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../routes/app_routes.dart';

/// Aviso fijo para el ROOT: con qué empresa está trabajando y un acceso a
/// la consola de empresas para cambiarla o crear una.
class RootViewingBanner extends StatelessWidget {
  const RootViewingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<CompanySession>();

    return Material(
      color: AppColors.primaryDark,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.sized(14, 32),
          vertical: 4,
        ),
        child: Obx(() {
          final company = session.viewing.value;
          return Row(
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  company == null
                      ? const TextSpan(text: 'ROOT · aún no hay empresas')
                      : TextSpan(
                          children: [
                            const TextSpan(text: 'ROOT · viendo '),
                            TextSpan(
                              text: company.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () => Get.toNamed(Routes.companies),
                icon: Icon(
                  company == null
                      ? LucideIcons.plus
                      : LucideIcons.arrowLeftRight,
                  size: 16,
                ),
                label: Text(company == null ? 'Crear' : 'Cambiar'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
