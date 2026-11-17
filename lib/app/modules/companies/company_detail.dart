import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/company_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/text_input_dialog.dart';
import '../../data/models/app_user.dart';
import '../../data/models/company.dart';
import '../../data/repositories/admin_repository.dart';
import '../../routes/app_routes.dart';
import '../root/root_controller.dart';
import '../documents/document_actions.dart';
import '../documents/documents.dart';
import '../root/widgets/app_shell.dart';
import 'widgets/company_status_chip.dart';
import 'widgets/user_tile.dart';

class CompanyDetailController extends GetxController {
  final _repo = Get.find<AdminRepository>();
  final String companyId = Get.arguments as String;

  final company = Rxn<Company>();
  final users = <AppUser>[].obs;
  final clients = <CompanyClientRow>[].obs;
  final stats = Rxn<CompanyStats>();

  @override
  void onInit() {
    super.onInit();
    company.bindStream(_repo.watchCompany(companyId));
    users.bindStream(_repo.watchUsers(companyId));
    clients.bindStream(_repo.watchClients(companyId));
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      stats.value = await _repo.stats(companyId);
    } catch (_) {}
  }

  Future<void> changeLimit() async {
    final c = company.value!;
    final value = await TextInputDialog.show(
      title: 'Límite de usuarios',
      label: 'Máximo de usuarios (hoy usa ${c.userCount})',
      initialValue: '${c.maxUsers}',
      keyboardType: TextInputType.number,
      validator: (v) {
        final n = int.tryParse(v);
        if (n == null || n < 1) return 'Escribe un número mayor que 0';
        if (n < c.userCount) {
          return 'Ya tiene ${c.userCount} usuarios; no puede ser menor';
        }
        return null;
      },
    );
    if (value == null) return;
    await _repo.updateCompany(companyId, maxUsers: int.parse(value));
  }

  Future<void> toggleActive() async {
    final c = company.value!;
    final suspend = c.active;
    final ok = await ConfirmDialog.show(
      title: suspend ? 'Suspender empresa' : 'Reactivar empresa',
      message: suspend
          ? 'Ningún usuario de ${c.name} podrá entrar a la app hasta que la '
                'reactives. Sus datos no se borran.'
          : 'Los usuarios activos de ${c.name} podrán volver a entrar.',
      confirmLabel: suspend ? 'Suspender' : 'Reactivar',
      destructive: suspend,
      icon: suspend ? LucideIcons.ban : LucideIcons.circleCheck,
    );
    if (ok) await _repo.updateCompany(companyId, active: !suspend);
  }

  /// Trabaja en la app con los datos de esta empresa.
  void enterCompany() {
    Get.find<CompanySession>().enter(company.value!);
    if (Get.isRegistered<RootController>()) {
      Get.find<RootController>().changeTab(RootController.home);
    }
    Get.until((route) => route.settings.name == Routes.root);
  }

  Future<void> toggleUser(AppUser user) =>
      _repo.setUserActive(user.uid, active: !user.active);
}

class CompanyDetailView extends GetView<CompanyDetailController> {
  const CompanyDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Empresa',
      showBack: true,
      activeTab: RootController.none,
      actions: [
        IconButton(
          tooltip: 'Compartir o imprimir',
          icon: const Icon(LucideIcons.share2, size: 20),
          onPressed: () {
            final c = controller.company.value;
            if (c == null) return;
            DocumentSheet.show(
              title: 'Resumen de la empresa',
              document: () => CompanyDoc(
                company: controller.company.value ?? c,
                users: controller.users,
                stats: controller.stats.value,
              ),
              fileName: 'empresa-${c.name.toLowerCase().replaceAll(' ', '-')}',
              shareText: 'Resumen de ${c.name}',
            );
          },
        ),
      ],
      body: Obx(() {
        final c = controller.company.value;
        if (c == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final gap = context.sized(12.0, 20.0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 1000;
            const users = _UsersCard();
            const clients = _ClientsCard();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.sized(14, 32),
                context.sized(14, 24),
                context.sized(14, 32),
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileCard(company: c),
                      SizedBox(height: gap),
                      const _Stats(),
                      SizedBox(height: gap),
                      const _Actions(),
                      SizedBox(height: gap),
                      if (twoColumns)
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: users),
                            SizedBox(width: 20),
                            Expanded(child: clients),
                          ],
                        )
                      else ...[
                        users,
                        SizedBox(height: gap),
                        clients,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (company.rnc != null) 'RNC ${company.rnc}',
      if (company.phone != null) company.phone!,
      'Dueño: ${company.ownerName}',
    ];

    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.building2,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: TextStyle(
                    fontSize: context.sized(19, 22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  details.join('  ·  '),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                CompanyStatusChip(active: company.active),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends GetView<CompanyDetailController> {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller.company.value!;
      final s = controller.stats.value;
      final tiles = [
        ('Usuarios', '${c.userCount} / ${c.maxUsers}', !c.hasFreeSeats),
        ('Clientes', s == null ? '—' : '${s.clients}', false),
        ('Cartera', s == null ? '—' : Formatters.currency(s.portfolio), false),
      ];
      return Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tiles[i].$1,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tiles[i].$2,
                        style: TextStyle(
                          fontSize: context.sized(17, 20),
                          fontWeight: FontWeight.w800,
                          color: tiles[i].$3
                              ? const Color(0xFFB7791F)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _Actions extends GetView<CompanyDetailController> {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.company.value!.active;
      final buttons = Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.changeLimit,
              icon: const Icon(LucideIcons.users, size: 18),
              label: const Text('Cambiar límite'),
              style: _style(AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.toggleActive,
              icon: Icon(
                active ? LucideIcons.ban : LucideIcons.circleCheck,
                size: 18,
              ),
              label: Text(active ? 'Suspender' : 'Reactivar'),
              style: _style(active ? AppColors.danger : AppColors.success),
            ),
          ),
        ],
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: controller.enterCompany,
            icon: const Icon(LucideIcons.logIn, size: 18),
            label: const Text('Trabajar con esta empresa'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          buttons,
        ],
      );
    });
  }

  static ButtonStyle _style(Color color) => OutlinedButton.styleFrom(
    foregroundColor: color,
    side: BorderSide(color: color.withValues(alpha: 0.5)),
    minimumSize: const Size.fromHeight(48),
    shape: const StadiumBorder(),
    textStyle: const TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w700,
    ),
  );
}

class _UsersCard extends GetView<CompanyDetailController> {
  const _UsersCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.users,
      title: 'Usuarios',
      child: Obx(
        () => controller.users.isEmpty
            ? const Text(
                'Sin usuarios.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            : Column(
                children: [
                  for (final u in controller.users)
                    UserTile(
                      user: u,
                      // El ROOT puede activar/desactivar a cualquiera.
                      onToggle: () => controller.toggleUser(u),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ClientsCard extends GetView<CompanyDetailController> {
  const _ClientsCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.contact,
      title: 'Clientes',
      child: Obx(() {
        if (controller.clients.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.contact,
            title: 'Sin clientes en la nube',
            message: 'Aparecerán aquí cuando la empresa registre clientes.',
          );
        }
        return Column(
          children: [
            for (final c in controller.clients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accentSoft,
                  child: Icon(
                    LucideIcons.user,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  c.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                subtitle: Text(c.document ?? 'Sin cédula'),
                trailing: Text(
                  Formatters.currency2(c.balance),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        );
      }),
    );
  }
}
