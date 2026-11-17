import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/auth_backend.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repository.dart';
import '../../routes/app_routes.dart';

enum ClientSegment { all, withLoan, withoutLoan }

enum ClientStatusFilter {
  all('Todos'),
  active('Activos'),
  inactive('Inactivos');

  const ClientStatusFilter(this.label);
  final String label;
}

enum ClientSort {
  name('Nombre (A–Z)'),
  id('ID');

  const ClientSort(this.label);
  final String label;
}

class ClientsController extends GetxController {
  final _repo = Get.find<ClientRepository>();
  RxList<Client> get _clients => _repo.clients;
  final searchController = TextEditingController();

  final query = ''.obs;
  final segment = ClientSegment.all.obs;
  final statusFilter = ClientStatusFilter.all.obs;
  final sort = ClientSort.name.obs;

  /// Lista resultante de aplicar búsqueda, segmento, filtros y orden.
  final visible = <Client>[].obs;

  @override
  void onInit() {
    super.onInit();
    _apply();
    debounce(query, (_) => _apply(), time: const Duration(milliseconds: 250));
    everAll([segment, statusFilter, sort, _clients], (_) => _apply());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Todos los clientes, sin filtros.
  List<Client> get all => _clients;

  int get totalCount => _clients.length;
  int get activeCount => _clients.where((c) => c.isActive).length;
  int get inactiveCount => totalCount - activeCount;
  int get withLoanCount => _clients.where((c) => c.hasLoan).length;
  int get withoutLoanCount => totalCount - withLoanCount;

  int countFor(ClientSegment s) => switch (s) {
    ClientSegment.all => totalCount,
    ClientSegment.withLoan => withLoanCount,
    ClientSegment.withoutLoan => withoutLoanCount,
  };

  bool get hasActiveFilters =>
      statusFilter.value != ClientStatusFilter.all ||
      sort.value != ClientSort.name;

  void search(String value) => query.value = value;

  void clearSearch() {
    searchController.clear();
    query.value = '';
  }

  void changeSegment(ClientSegment value) => segment.value = value;

  void applyFilters(ClientStatusFilter status, ClientSort order) {
    statusFilter.value = status;
    sort.value = order;
  }

  void resetFilters() => applyFilters(ClientStatusFilter.all, ClientSort.name);

  void openNewClient() => Get.toNamed(Routes.clientNew);

  void openClient(Client client) =>
      Get.toNamed(Routes.clientDetail, arguments: client.id);

  // Acciones de cada cliente. Las usan el menú ⋮ de la lista y la ficha.

  void editClient(Client client) =>
      Get.toNamed(Routes.clientEdit, arguments: client.id);

  Future<void> toggleActive(Client client) async {
    final activate = !client.isActive;
    final confirmed = await ConfirmDialog.show(
      title: activate ? 'Activar cliente' : 'Inactivar cliente',
      message: activate
          ? '${client.name} volverá a aparecer como activo y podrá recibir '
                'nuevos préstamos.'
          : '${client.name} no podrá recibir nuevos préstamos. Su historial '
                'se conserva y puedes activarlo cuando quieras.',
      confirmLabel: activate ? 'Activar' : 'Inactivar',
      icon: activate ? LucideIcons.userCheck : LucideIcons.userX,
    );
    if (!confirmed) return;

    try {
      await _repo.setActive(client.id, active: activate);
    } on AuthFailure catch (e) {
      _notify('No se pudo actualizar', e.message);
      return;
    }
    _notify(activate ? 'Cliente activado' : 'Cliente inactivado', client.name);
  }

  /// Devuelve true si se eliminó (la ficha lo usa para cerrarse).
  Future<bool> deleteClient(Client client) async {
    if (client.hasLoan) {
      await ConfirmDialog.show(
        title: 'No se puede eliminar',
        message:
            '${client.name} tiene un préstamo activo. Salda o cancela el '
            'préstamo primero, o inactiva al cliente.',
        confirmLabel: 'Entendido',
        showCancel: false,
        icon: LucideIcons.info,
      );
      return false;
    }

    final confirmed = await ConfirmDialog.show(
      title: 'Eliminar cliente',
      message:
          'Se eliminará a ${client.name} de forma permanente. Esta acción '
          'no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!confirmed) return false;

    try {
      await _repo.delete(client.id);
    } on AuthFailure catch (e) {
      _notify('No se pudo eliminar', e.message);
      return false;
    }
    _notify('Cliente eliminado', client.name);
    return true;
  }

  void _notify(String title, String message) => Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(16),
  );

  void _apply() {
    final q = normalize(query.value.trim());

    final result = _clients.where((c) {
      final matchesSegment = switch (segment.value) {
        ClientSegment.all => true,
        ClientSegment.withLoan => c.hasLoan,
        ClientSegment.withoutLoan => !c.hasLoan,
      };
      final matchesStatus = switch (statusFilter.value) {
        ClientStatusFilter.all => true,
        ClientStatusFilter.active => c.isActive,
        ClientStatusFilter.inactive => !c.isActive,
      };
      final matchesQuery =
          q.isEmpty ||
          normalize(c.displayName).contains(q) ||
          c.id.contains(q) ||
          (c.document?.replaceAll('-', '').contains(q.replaceAll('-', '')) ??
              false) ||
          (c.phone?.replaceAll('-', '').contains(q.replaceAll('-', '')) ??
              false);
      return matchesSegment && matchesStatus && matchesQuery;
    }).toList();

    switch (sort.value) {
      case ClientSort.name:
        result.sort((a, b) => normalize(a.name).compareTo(normalize(b.name)));
      case ClientSort.id:
        result.sort(
          (a, b) =>
              (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0),
        );
    }

    visible.assignAll(result);
  }

  /// Minúsculas y sin acentos, para que "martinez" encuentre "Martínez".
  static String normalize(String value) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i == -1 ? ch : to[i]);
    }
    return buffer.toString();
  }
}
