import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/utils/responsive.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/client.dart';
import 'clients_controller.dart';
import 'widgets/client_card.dart';
import 'widgets/client_search_bar.dart';
import 'widgets/client_segments.dart';
import 'widgets/clients_header.dart';
import 'widgets/clients_summary.dart';

class ClientsView extends GetView<ClientsController> {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mismo ancho máximo y márgenes que el resto de pantallas.
        final side = math.max(
          compact ? 14.0 : 32.0,
          (constraints.maxWidth - 1200) / 2,
        );
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        final gap = context.sized(14, 20);

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, gap, side, 0),
              sliver: SliverList.list(
                children: [
                  const ClientsHeader(),
                  SizedBox(height: gap),
                  const ClientsSummary(),
                  SizedBox(height: gap),
                  const ClientSearchBar(),
                  const SizedBox(height: 12),
                  const ClientSegments(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 0, side, compact ? 120 : 32),
              sliver: Obx(() {
                final clients = controller.visible;

                if (clients.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: LucideIcons.searchX,
                      title: 'Sin resultados',
                      message:
                          'Prueba con otro nombre, ID o cambia los filtros.',
                    ),
                  );
                }

                if (columns == 1) {
                  return SliverList.separated(
                    itemCount: clients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(clients[i]).entrance(i),
                  );
                }

                return SliverGrid.builder(
                  itemCount: clients.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 84,
                  ),
                  itemBuilder: (_, i) => _card(clients[i]).entrance(i),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _card(Client client) => ClientCard(
    key: ValueKey(client.id),
    client: client,
    onTap: () => controller.openClient(client),
    onEdit: () => controller.editClient(client),
    onToggleActive: () => controller.toggleActive(client),
    onDelete: () => controller.deleteClient(client),
  );
}
