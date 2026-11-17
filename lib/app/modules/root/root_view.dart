import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/motion.dart';

import '../clients/clients_view.dart';
import '../home/home_view.dart';
import '../loans/loans_view.dart';
import '../movements/movements_view.dart';
import '../reports/reports_view.dart';
import 'root_controller.dart';
import 'widgets/app_shell.dart';

class RootView extends GetView<RootController> {
  const RootView({super.key});

  static const _pages = <Widget>[
    HomeView(),
    ClientsView(),
    LoansView(),
    MovementsView(),
    ReportsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Obx(
        () => FadeIndexedStack(
          index: controller.currentIndex.value,
          children: _pages,
        ),
      ),
    );
  }
}
