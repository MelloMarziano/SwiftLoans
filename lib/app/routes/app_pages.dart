import 'package:get/get.dart';

import '../modules/cash_closing/cash_closing_controller.dart';
import '../modules/cash_closing/cash_closing_view.dart';
import '../modules/companies/companies_controller.dart';
import '../modules/expenses/expenses_controller.dart';
import '../modules/expenses/expenses_view.dart';
import '../modules/companies/companies_view.dart';
import '../modules/companies/company_detail.dart';
import '../modules/companies/company_form.dart';
import '../modules/collect/collect_controller.dart';
import '../modules/collect/collect_view.dart';
import '../modules/receipt/receipt_view.dart';
import '../modules/auth/change_password_view.dart';
import '../modules/auth/login_view.dart';
import '../modules/client_detail/client_detail_view.dart';
import '../modules/client_form/client_form_controller.dart';
import '../modules/client_form/client_form_view.dart';
import '../modules/loan_request/loan_request_controller.dart';
import '../modules/loans/loan_detail_view.dart';
import '../modules/loan_request/loan_request_view.dart';
import '../modules/loan_request/loan_schedule_view.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/root/root_binding.dart';
import '../modules/settings/pages/business_settings.dart';
import '../modules/settings/pages/loan_defaults_settings.dart';
import '../modules/settings/pages/maintenance_settings.dart';
import '../modules/settings/pages/printer_settings.dart';
import '../modules/settings/pages/routes_settings.dart';
import '../modules/settings/settings_view.dart';
import '../modules/team/team.dart';
import '../modules/root/root_view.dart';
import 'app_routes.dart';
import 'auth_guard.dart';

final _clientFormBinding = BindingsBuilder(() {
  Get.lazyPut(() => ClientFormController());
});

abstract class AppPages {
  static const initial = Routes.root;

  /// Todas las pantallas excepto el login y el cambio de contraseña
  /// requieren sesión.
  static final routes = <GetPage>[
    GetPage(name: Routes.login, page: () => const LoginView()),
    GetPage(
      name: Routes.changePassword,
      page: () => const ChangePasswordView(),
    ),
    ..._protected.map((p) => p.copy(middlewares: [AuthGuard()])),
    // Solo ROOT
    ..._rootOnly.map(
      (p) => p.copy(middlewares: [AuthGuard(), RoleGuard((u) => u.isRoot)]),
    ),
    // Solo dueño y administrador de una empresa
    ..._managersOnly.map(
      (p) => p.copy(
        middlewares: [AuthGuard(), RoleGuard((u) => u.role.managesUsers)],
      ),
    ),
  ];

  static final _rootOnly = <GetPage>[
    GetPage(
      name: Routes.companies,
      page: () => const CompaniesConsoleView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CompaniesController());
      }),
    ),
    GetPage(
      name: Routes.companyNew,
      page: () => const CompanyFormView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CompanyFormController());
      }),
    ),
    GetPage(
      name: Routes.companyDetail,
      page: () => const CompanyDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CompanyDetailController());
      }),
    ),
  ];

  static final _managersOnly = <GetPage>[
    GetPage(
      name: Routes.team,
      page: () => const TeamView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TeamController());
      }),
    ),
    GetPage(
      name: Routes.teamNew,
      page: () => const NewUserView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NewUserController());
      }),
    ),
  ];

  static final _protected = <GetPage>[
    GetPage(
      name: Routes.root,
      page: () => const RootView(),
      binding: RootBinding(),
    ),
    // Pantallas pendientes: se reemplazan a medida que se construyan.
    GetPage(
      name: Routes.collect,
      page: () => const CollectView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CollectController());
      }),
    ),
    GetPage(name: Routes.paymentReceipt, page: () => const ReceiptView()),
    GetPage(
      name: Routes.loanRequest,
      page: () => const LoanRequestView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoanRequestController());
      }),
    ),
    GetPage(name: Routes.loanSchedule, page: () => const LoanScheduleView()),
    GetPage(name: Routes.loanDetail, page: () => const LoanDetailView()),
    GetPage(
      name: Routes.expenses,
      page: () => const ExpensesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ExpensesController());
      }),
    ),
    GetPage(
      name: Routes.cashClosing,
      page: () => const CashClosingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CashClosingController());
      }),
    ),
    GetPage(name: Routes.notifications, page: () => const NotificationsView()),
    GetPage(
      name: Routes.clientNew,
      page: () => const ClientFormView(),
      binding: _clientFormBinding,
    ),
    GetPage(
      name: Routes.clientEdit,
      page: () => const ClientFormView(),
      binding: _clientFormBinding,
    ),
    GetPage(name: Routes.clientDetail, page: () => const ClientDetailView()),
    GetPage(name: Routes.settings, page: () => const SettingsView()),
    GetPage(
      name: Routes.settingsBusiness,
      page: () => const BusinessSettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => BusinessSettingsController());
      }),
    ),
    GetPage(
      name: Routes.settingsLoans,
      page: () => const LoanDefaultsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoanDefaultsController());
      }),
    ),
    GetPage(
      name: Routes.settingsRoutes,
      page: () => const RoutesSettingsView(),
    ),
    GetPage(
      name: Routes.settingsPrinter,
      page: () => const PrinterSettingsView(),
    ),
    GetPage(
      name: Routes.settingsMaintenance,
      page: () => const MaintenanceSettingsView(),
    ),
  ];
}
