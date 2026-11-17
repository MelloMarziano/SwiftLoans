import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'app/core/services/auth_backend.dart';
import 'app/core/services/auth_service.dart';
import 'app/core/services/company_session.dart';
import 'app/core/services/company_settings_sync.dart';
import 'app/core/services/demo_mode.dart';
import 'app/core/services/key_value_store.dart';
import 'app/core/services/notification_service.dart';
import 'app/core/services/session_service.dart';
import 'app/core/services/printer_service.dart';
import 'app/core/services/settings_service.dart';
import 'app/data/repositories/client_repository.dart';
import 'app/data/repositories/closing_repository.dart';
import 'app/data/repositories/expense_repository.dart';
import 'app/data/repositories/loan_repository.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/models/app_user.dart';
import 'app/data/repositories/admin_repository.dart';
import 'app/data/sources/company_data_source.dart';
import 'app/data/sources/firestore_company_data_source.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  final store = GetStorageStore();
  Get.put(SettingsService(store: store), permanent: true);
  Get.put(PrinterService(), permanent: true);
  final auth = Get.put(
    AuthService(backend: FirebaseAuthBackend(), store: store),
    permanent: true,
  );
  await auth.restore();
  Get.put<AdminRepository>(
    DemoAwareAdminRepository(
      FirestoreAdminRepository(),
      DemoMode.adminRepository(),
    ),
    permanent: true,
  );
  Get.put(
    CompanySession(DemoMode.sourceFactory(FirestoreCompanyDataSource.new)),
    permanent: true,
  );

  runApp(const SwiftLoansApp());
}

class SwiftLoansApp extends StatelessWidget {
  const SwiftLoansApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SwiftLoans',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('es', 'DO'),
      fallbackLocale: const Locale('es'),
      supportedLocales: const [Locale('es', 'DO'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialBinding: BindingsBuilder(() {
        // En la app ya vienen registrados desde main(); en los tests y las
        // vistas previas se usan versiones en memoria: un dueño de empresa
        // con datos de ejemplo.
        if (!Get.isRegistered<SettingsService>()) {
          Get.put(SettingsService(store: MemoryStore()), permanent: true);
        }
        if (!Get.isRegistered<PrinterService>()) {
          Get.put(PrinterService(), permanent: true);
        }
        if (!Get.isRegistered<AdminRepository>()) {
          Get.put<AdminRepository>(InMemoryAdminRepository(), permanent: true);
        }
        if (!Get.isRegistered<AuthService>()) {
          Get.put(
            AuthService(backend: FakeAuthBackend(), store: MemoryStore())
              ..user.value = const AppUser(
                uid: 'demo-owner',
                username: 'francisco',
                name: 'Francisco',
                role: UserRole.owner,
                companyId: 'demo',
              ),
            permanent: true,
          );
        }
        if (!Get.isRegistered<CompanySession>()) {
          Get.put(
            CompanySession((_) => SampleCompanyDataSource()),
            permanent: true,
          );
        }
        Get.put(SessionService(), permanent: true);
        Get.put(CompanySettingsSync(), permanent: true);
        // LoanRepository primero: ClientRepository calcula estados con él.
        Get.put(LoanRepository(), permanent: true);
        Get.put(ClientRepository(), permanent: true);
        Get.put(ExpenseRepository(), permanent: true);
        Get.put(ClosingRepository(), permanent: true);
        Get.put(
          NotificationService(store: Get.find<SettingsService>().store),
          permanent: true,
        );
      }),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 599, name: MOBILE),
          Breakpoint(start: 600, end: 1023, name: TABLET),
          Breakpoint(start: 1024, end: double.infinity, name: DESKTOP),
        ],
      ),
    );
  }
}
