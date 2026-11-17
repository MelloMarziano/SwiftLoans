import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/models/company.dart';
import '../../data/repositories/admin_repository.dart';
import '../../routes/app_routes.dart';
import '../clients/clients_controller.dart';

/// Consola del ROOT: todas las empresas con sus totales.
class CompaniesController extends GetxController {
  final _repo = Get.find<AdminRepository>();

  final companies = <Company>[].obs;
  final stats = <String, CompanyStats>{}.obs;
  final query = ''.obs;
  final isLoading = true.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    companies.bindStream(_repo.watchCompanies());
    ever(companies, (list) {
      isLoading.value = false;
      _loadStats(list);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  List<Company> get visible {
    final q = ClientsController.normalize(query.value.trim());
    if (q.isEmpty) return companies;
    return companies
        .where(
          (c) =>
              ClientsController.normalize(c.name).contains(q) ||
              ClientsController.normalize(c.ownerName).contains(q) ||
              (c.rnc ?? '').contains(q),
        )
        .toList();
  }

  int get activeCount => companies.where((c) => c.active).length;
  int get userCount => companies.fold(0, (s, c) => s + c.userCount);
  double get portfolio => stats.values.fold(0, (s, x) => s + x.portfolio);
  int get clientCount => stats.values.fold(0, (s, x) => s + x.clients);

  void openCompany(Company c) =>
      Get.toNamed(Routes.companyDetail, arguments: c.id);

  void newCompany() => Get.toNamed(Routes.companyNew);

  Future<void> refreshStats() => _loadStats(companies);

  Future<void> _loadStats(List<Company> list) async {
    for (final c in list) {
      try {
        stats[c.id] = await _repo.stats(c.id);
      } catch (_) {
        // Sin conexión o sin permiso: se deja sin totales.
      }
    }
  }
}
