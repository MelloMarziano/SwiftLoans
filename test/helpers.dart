import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_backend.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/services/company_session.dart';
import 'package:swiftloans/app/core/services/key_value_store.dart';
import 'package:swiftloans/app/core/services/session_service.dart';
import 'package:swiftloans/app/core/services/settings_service.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/repositories/client_repository.dart';
import 'package:swiftloans/app/data/repositories/closing_repository.dart';
import 'package:swiftloans/app/data/repositories/expense_repository.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';
import 'package:swiftloans/app/data/sources/company_data_source.dart';

/// Empresa de ejemplo con sesión de un cobrador, como la usa la app.
Future<void> setUpSampleCompany({String userName = 'Pedro Cobrador'}) async {
  Get.testMode = true;
  Get.put(SettingsService(store: MemoryStore()));
  Get.put(
    AuthService(backend: FakeAuthBackend(), store: MemoryStore())
      ..user.value = AppUser(
        uid: 'c1',
        username: 'pedro',
        name: userName,
        role: UserRole.collector,
        companyId: 'demo',
      ),
  );
  Get.put(CompanySession((_) => SampleCompanyDataSource()));
  Get.put(SessionService());
  Get.put(LoanRepository());
  Get.put(ClientRepository());
  Get.put(ExpenseRepository());
  Get.put(ClosingRepository());
  await settle();
}

/// Deja que lleguen los datos de los streams.
Future<void> settle() => Future<void>.delayed(Duration.zero);
