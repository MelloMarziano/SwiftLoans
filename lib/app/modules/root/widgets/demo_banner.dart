import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../routes/app_routes.dart';

/// Aviso fijo en la demo: los datos son de ejemplo y no se guardan.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  Future<void> _exit() async {
    await Get.find<AuthService>().signOut();
    Get.offAllNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB7791F),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.sized(14, 32),
          vertical: 4,
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.flaskConical, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Modo demo',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' · datos de ejemplo'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _exit,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Salir'),
            ),
          ],
        ),
      ),
    );
  }
}
