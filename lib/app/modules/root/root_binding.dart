import 'package:get/get.dart';

import '../clients/clients_controller.dart';
import '../home/home_controller.dart';
import '../loans/loans_controller.dart';
import '../movements/movements_controller.dart';
import '../reports/reports_controller.dart';
import 'root_controller.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(RootController());
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => ClientsController());
    Get.lazyPut(() => LoansController());
    Get.lazyPut(() => MovementsController());
    Get.lazyPut(() => ReportsController());
  }
}
