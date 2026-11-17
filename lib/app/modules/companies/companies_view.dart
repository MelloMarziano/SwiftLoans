import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/motion.dart';
import '../../data/models/company.dart';
import '../root/root_controller.dart';
import '../root/widgets/app_shell.dart';
import 'companies_controller.dart';
import 'widgets/company_status_chip.dart';

/// Consola del ROOT (Ajustes → Empresas): administra las empresas que usan
/// la app y elige con cuál trabajar.
class CompaniesConsoleView extends StatelessWidget {
  const CompaniesConsoleView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Empresas',
      showBack: true,
      activeTab: RootController.none,
      body: CompaniesView(),
    );
  }
}

class CompaniesView extends GetView<CompaniesController> {
  const CompaniesView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          context.sized(14.0, 32.0),
          (constraints.maxWidth - 1200) / 2,
        );
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        final gap = context.sized(14.0, 20.0);

        return RefreshIndicator(
          onRefresh: controller.refreshStats,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, gap, side, 0),
                sliver: SliverList.list(
                  children: [
                    const _Header(),
                    SizedBox(height: gap),
                    const _Summary(),
                    SizedBox(height: gap),
                    _SearchField(controller: controller),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, 0, side, 32),
                sliver: Obx(() {
                  if (controller.isLoading.value) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  final list = controller.visible;
                  if (list.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyState(
                        icon: LucideIcons.building2,
                        title: controller.companies.isEmpty
                            ? 'Aún no hay empresas'
                            : 'Sin resultados',
                        message: controller.companies.isEmpty
                            ? 'Crea la primera empresa con su usuario dueño.'
                            : 'Prueba con otro nombre.',
                      ),
                    );
                  }
                  return SliverGrid.builder(
                    itemCount: list.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 148,
                    ),
                    itemBuilder: (_, i) => _CompanyCard(
                      key: ValueKey(list[i].id),
                      company: list[i],
                    ).entrance(i),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends GetView<CompaniesController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Empresas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                'Administra las empresas que usan SwiftLoans',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: controller.newCompany,
          icon: Icon(LucideIcons.plus, size: compact ? 18 : 20),
          label: const Text('Nueva empresa'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: const StadiumBorder(),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: compact ? 10 : 14,
            ),
            textStyle: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Summary extends GetView<CompaniesController> {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tiles = [
        (
          LucideIcons.building2,
          'Empresas',
          '${controller.companies.length}',
          '${controller.activeCount} activas',
        ),
        (
          LucideIcons.users,
          'Usuarios',
          '${controller.userCount}',
          'en todas las empresas',
        ),
        (
          LucideIcons.contact,
          'Clientes',
          '${controller.clientCount}',
          'registrados',
        ),
        (
          LucideIcons.wallet,
          'Cartera total',
          Formatters.compact(controller.portfolio),
          'por cobrar',
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 4 : 2;
          final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (icon, label, value, caption) in tiles)
                SizedBox(
                  width: width,
                  child: _SummaryTile(
                    icon: icon,
                    label: label,
                    value: value,
                    caption: caption,
                  ),
                ),
            ],
          );
        },
      );
    });
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.sized(12, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: context.sized(12, 13),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: context.sized(18, 22),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final CompaniesController controller;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: c, width: w),
    );

    return SizedBox(
      height: context.sized(46.0, 52.0),
      child: TextField(
        controller: controller.searchController,
        onChanged: (v) => controller.query.value = v,
        decoration: InputDecoration(
          hintText: 'Buscar empresa, dueño o RNC...',
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.zero,
          border: border(AppColors.border),
          enabledBorder: border(AppColors.border),
          focusedBorder: border(AppColors.primary, 1.5),
        ),
      ),
    );
  }
}

class _CompanyCard extends GetView<CompaniesController> {
  const _CompanyCard({super.key, required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () => controller.openCompany(company),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: company.active
                            ? AppColors.accentSoft
                            : const Color(0xFFEFF3F4),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        LucideIcons.building2,
                        size: 21,
                        color: company.active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Dueño: ${company.ownerName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CompanyStatusChip(active: company.active),
                  ],
                ),
                const Spacer(),
                Obx(() {
                  final s = controller.stats[company.id];
                  return Row(
                    children: [
                      _Metric(
                        icon: LucideIcons.users,
                        text:
                            '${company.userCount}/${company.maxUsers} usuarios',
                        warn: !company.hasFreeSeats,
                      ),
                      const SizedBox(width: 14),
                      _Metric(
                        icon: LucideIcons.contact,
                        text: s == null
                            ? '— clientes'
                            : s.clients == 1
                            ? '1 cliente'
                            : '${s.clients} clientes',
                      ),
                      const Spacer(),
                      Text(
                        s == null ? '—' : Formatters.currency(s.portfolio),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.text, this.warn = false});

  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final color = warn ? const Color(0xFFB7791F) : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color, fontSize: 12.5)),
      ],
    );
  }
}
