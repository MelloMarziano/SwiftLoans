import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/models/client.dart';
import '../../clients/clients_controller.dart';
import '../../clients/widgets/client_status_chip.dart';

/// Hoja inferior para buscar y elegir un cliente.
class ClientPickerSheet extends StatefulWidget {
  const ClientPickerSheet({
    super.key,
    this.current,
    this.title = 'Selecciona un cliente',
    this.filter,
  });

  final Client? current;
  final String title;

  /// Qué clientes se muestran; por defecto, solo los activos.
  final bool Function(Client)? filter;

  static Future<Client?> show({
    Client? current,
    String title = 'Selecciona un cliente',
    bool Function(Client)? filter,
  }) => Get.bottomSheet<Client>(
    ClientPickerSheet(current: current, title: title, filter: filter),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );

  @override
  State<ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<ClientPickerSheet> {
  late final List<Client> _clients;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _clients =
        Get.find<ClientRepository>().clients
            .where(widget.filter ?? (c) => c.isActive)
            .toList()
          ..sort(
            (a, b) => ClientsController.normalize(
              a.name,
            ).compareTo(ClientsController.normalize(b.name)),
          );
  }

  List<Client> get _filtered {
    final q = ClientsController.normalize(_query.trim());
    if (q.isEmpty) return _clients;
    return _clients
        .where(
          (c) =>
              ClientsController.normalize(c.displayName).contains(q) ||
              c.id.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.75;
    final clients = _filtered;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: height),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o ID',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: clients.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin resultados',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        itemCount: clients.length,
                        itemBuilder: (_, i) {
                          final c = clients[i];
                          final selected = c.id == widget.current?.id;
                          return ListTile(
                            onTap: () => Get.back(result: c),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            selected: selected,
                            selectedTileColor: AppColors.accentSoft,
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.accentSoft,
                              child: Icon(
                                LucideIcons.user,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              c.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${c.id}  |  ${c.document ?? 'N/A'}',
                            ),
                            trailing: selected
                                ? const Icon(
                                    LucideIcons.check,
                                    color: AppColors.primary,
                                  )
                                : c.hasLoan
                                ? ClientStatusChip(status: c.loanStatus)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
