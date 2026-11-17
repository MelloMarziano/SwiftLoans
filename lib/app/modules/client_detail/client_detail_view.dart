import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/finance/loan_ledger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../clients/clients_controller.dart';
import '../clients/widgets/client_status_chip.dart';
import '../root/root_controller.dart';
import '../documents/document_actions.dart';
import '../documents/documents.dart';
import '../root/widgets/app_shell.dart';

/// Ficha del cliente. Recibe el ID como argumento y se actualiza sola cuando
/// el cliente se edita o cambia de estado.
class ClientDetailView extends StatelessWidget {
  const ClientDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.arguments as String?;
    final repo = Get.find<ClientRepository>();

    return AppShell(
      title: 'Ficha del cliente',
      showBack: true,
      activeTab: RootController.clients,
      actions: [
        IconButton(
          tooltip: 'Compartir o imprimir',
          icon: const Icon(LucideIcons.share2, size: 20),
          onPressed: () {
            final client = id == null ? null : repo.byId(id);
            if (client == null) return;
            DocumentSheet.show(
              title: 'Ficha del cliente',
              document: () => ClientDoc(client: repo.byId(client.id) ?? client),
              fileName: 'cliente-${client.id}',
              shareText: 'Ficha de ${client.name}',
            );
          },
        ),
      ],
      body: Obx(() {
        final client = id == null ? null : repo.byId(id);
        if (client == null) {
          return const EmptyState(
            icon: LucideIcons.userX,
            title: 'Cliente no encontrado',
            message: 'Es posible que haya sido eliminado.',
          );
        }
        return _Body(client: client);
      }),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 1000;
        final gap = context.sized(12, 20);

        final personal = _InfoCard(
          icon: LucideIcons.idCard,
          title: 'Datos personales',
          rows: [
            (LucideIcons.idCard, 'Cédula', client.document),
            (LucideIcons.smile, 'Apodo', client.alias),
            (LucideIcons.briefcase, 'Ocupación', client.occupation),
          ],
        );
        final contact = _InfoCard(
          icon: LucideIcons.mapPin,
          title: 'Contacto y dirección',
          rows: [
            (LucideIcons.phone, 'Teléfono', client.phone),
            (LucideIcons.phone, 'Teléfono 2', client.phone2),
            (LucideIcons.house, 'Dirección', client.address),
            (LucideIcons.map, 'Sector / Ciudad', client.sector),
            (LucideIcons.route, 'Ruta / Oficina', client.route),
          ],
        );
        final reference = _InfoCard(
          icon: LucideIcons.contact,
          title: 'Referencia',
          rows: [
            (LucideIcons.user, 'Nombre', client.referenceName),
            (LucideIcons.phone, 'Teléfono', client.referencePhone),
          ],
        );
        final notes = _InfoCard(
          icon: LucideIcons.stickyNote,
          title: 'Notas',
          rows: [(LucideIcons.fileText, 'Observaciones', client.notes)],
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            context.sized(14, 32),
            context.sized(14, 24),
            context.sized(14, 32),
            context.isCompact ? 120 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(client: client),
                  SizedBox(height: gap),
                  _Actions(client: client),
                  SizedBox(height: gap),
                  _LoanAndPayments(clientId: client.id, gap: gap),
                  if (twoColumns)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              personal,
                              SizedBox(height: gap),
                              reference,
                            ],
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: Column(
                            children: [
                              contact,
                              SizedBox(height: gap),
                              notes,
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    personal,
                    SizedBox(height: gap),
                    contact,
                    SizedBox(height: gap),
                    reference,
                    SizedBox(height: gap),
                    notes,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final size = context.sized(60.0, 72.0);
    final inactive = !client.isActive;

    return SectionCard(
      child: Row(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: inactive
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
              color: inactive ? const Color(0xFFE6ECEE) : null,
            ),
            child: Text(
              client.initials,
              style: TextStyle(
                color: inactive ? AppColors.textSecondary : Colors.white,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: context.sized(14, 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: TextStyle(
                    fontSize: context.sized(19, 22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  [
                    'ID: ${client.id}',
                    if (client.alias != null) '"${client.alias}"',
                  ].join('  ·  '),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: context.sized(13, 14),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _ActiveBadge(active: client.isActive),
                    ClientStatusChip(status: client.loanStatus),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.sized(9, 12),
        vertical: context.sized(5, 7),
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.successSoft : const Color(0xFFEFF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: color,
              fontSize: context.sized(12, 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nueva solicitud + Editar / Inactivar / Eliminar.
class _Actions extends StatelessWidget {
  const _Actions({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final clients = Get.find<ClientsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (client.hasLoan) ...[
          // Con préstamo activo, lo principal es cobrar.
          FilledButton.icon(
            onPressed: () => Get.toNamed(Routes.collect, arguments: client),
            icon: const Icon(LucideIcons.banknote, size: 20),
            label: const Text('Aplicar pago'),
            style: _primaryStyle(context),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: client.isActive
                ? () => Get.toNamed(Routes.loanRequest, arguments: client)
                : null,
            icon: const Icon(LucideIcons.filePlus, size: 20),
            label: const Text('Nueva solicitud'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: Size.fromHeight(context.sized(46, 50)),
              shape: const StadiumBorder(),
              textStyle: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: context.sized(14, 15),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ] else
          FilledButton.icon(
            onPressed: client.isActive
                ? () => Get.toNamed(Routes.loanRequest, arguments: client)
                : null,
            icon: const Icon(LucideIcons.filePlus, size: 20),
            label: Text(
              client.isActive
                  ? 'Nueva solicitud'
                  : 'Activa al cliente para crear una solicitud',
            ),
            style: _primaryStyle(context),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: LucideIcons.pencil,
                label: 'Editar',
                color: AppColors.primary,
                onTap: () => clients.editClient(client),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: client.isActive
                    ? LucideIcons.userX
                    : LucideIcons.userCheck,
                label: client.isActive ? 'Inactivar' : 'Activar',
                color: client.isActive
                    ? const Color(0xFFB7791F)
                    : AppColors.success,
                onTap: () => clients.toggleActive(client),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: LucideIcons.trash2,
                label: 'Eliminar',
                color: AppColors.danger,
                onTap: () async {
                  if (await clients.deleteClient(client)) Get.back();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

ButtonStyle _primaryStyle(BuildContext context) => FilledButton.styleFrom(
  backgroundColor: AppColors.primary,
  minimumSize: Size.fromHeight(context.sized(50, 54)),
  shape: const StadiumBorder(),
  textStyle: TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: context.sized(15, 16),
    fontWeight: FontWeight.w800,
  ),
);

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: context.sized(10, 14)),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Icon(icon, size: context.sized(20, 22), color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: context.sized(12.5, 14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<(IconData, String, String?)> rows;

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: icon,
      title: title,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 18, color: AppColors.border),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(rows[i].$1, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                SizedBox(
                  width: context.sized(110, 140),
                  child: Text(
                    rows[i].$2,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: context.sized(13, 14),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i].$3 ?? '—',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: context.sized(14, 15),
                      fontWeight: FontWeight.w600,
                      color: rows[i].$3 == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Préstamo activo y últimos pagos del cliente.
class _LoanAndPayments extends StatelessWidget {
  const _LoanAndPayments({required this.clientId, required this.gap});

  final String clientId;
  final double gap;

  static final _date = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final loans = Get.find<LoanRepository>();

    return Obx(() {
      final loan = loans.activeLoanOf(clientId);
      final payments = loans.paymentsOf(clientId).take(5).toList();
      if (loan == null && payments.isEmpty) return const SizedBox.shrink();

      final s = loan == null ? null : LoanLedger.snapshot(loan, loans.today);
      final next = s?.nextInstallment;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loan != null && s != null)
            _InfoCard(
              icon: LucideIcons.layers,
              title: 'Préstamo ${loan.id}',
              rows: [
                (
                  LucideIcons.dollarSign,
                  'Monto',
                  Formatters.currency2(loan.amount),
                ),
                (
                  LucideIcons.wallet,
                  'Saldo total',
                  Formatters.currency2(s.balance),
                ),
                (
                  LucideIcons.clockAlert,
                  'Cuotas vencidas',
                  s.overdueCount == 0
                      ? 'Ninguna'
                      : '${s.overdueCount} · mora ${Formatters.currency2(s.lateFeeDue)}',
                ),
                (
                  LucideIcons.calendar,
                  'Próxima cuota',
                  next == null
                      ? null
                      : '#${next.number} · ${_date.format(next.dueDate)} · '
                            '${Formatters.currency2(next.pending)}',
                ),
              ],
            ),
          if (payments.isNotEmpty) ...[
            if (loan != null) SizedBox(height: gap),
            FormSectionCard(
              icon: LucideIcons.receiptText,
              title: 'Últimos pagos',
              child: Column(
                children: [
                  for (final p in payments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () =>
                          Get.toNamed(Routes.paymentReceipt, arguments: p.id),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.successSoft,
                        child: Icon(
                          LucideIcons.circleCheck,
                          size: 18,
                          color: AppColors.success,
                        ),
                      ),
                      title: Text(
                        Formatters.currency2(p.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${p.id} · ${_date.format(p.date)} · ${p.method.label}',
                      ),
                      trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    ),
                ],
              ),
            ),
          ],
          SizedBox(height: gap),
        ],
      );
    });
  }
}
