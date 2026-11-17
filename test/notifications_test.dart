import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/services/key_value_store.dart';
import 'package:swiftloans/app/core/services/notification_service.dart';
import 'package:swiftloans/app/core/services/session_service.dart';
import 'package:swiftloans/app/data/models/app_user.dart';
import 'package:swiftloans/app/data/models/loan.dart';
import 'package:swiftloans/app/data/repositories/closing_repository.dart';
import 'package:swiftloans/app/data/repositories/loan_repository.dart';

import 'helpers.dart';

void main() {
  tearDown(Get.reset);

  Future<NotificationService> service({
    AppUser? as,
    KeyValueStore? store,
  }) async {
    await setUpSampleCompany(); // Pedro Cobrador (c1)
    if (as != null) Get.find<AuthService>().user.value = as;
    final s = Get.put(NotificationService(store: store ?? MemoryStore()));
    await settle();
    s.recompute();
    return s;
  }

  const owner = AppUser(
    uid: 'demo-owner',
    username: 'francisco',
    name: 'Francisco',
    role: UserRole.owner,
    companyId: 'demo',
  );

  test(
    'el cobrador ve cobros, atrasos y su fondo, no los de gerencia',
    () async {
      final s = await service();
      final kinds = s.notifications.map((n) => n.kind).toSet();
      expect(kinds, contains(NotificationKind.dueToday));
      expect(kinds, contains(NotificationKind.overdue));
      expect(kinds, contains(NotificationKind.fund)); // Pedro tiene fondo hoy
      expect(kinds, isNot(contains(NotificationKind.closingPending)));
      expect(kinds, isNot(contains(NotificationKind.newLoan)));

      // Una notificación por préstamo atrasado.
      final overdue = Get.find<LoanRepository>().loans.where(
        (l) => l.installments.any(
          (i) =>
              !i.isPaid &&
              i.dueDate.isBefore(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
        ),
      );
      expect(
        s.notifications.where((n) => n.kind == NotificationKind.overdue).length,
        lessThanOrEqualTo(overdue.length),
      );
      // El resumen del día va de primero.
      expect(s.notifications.first.kind, NotificationKind.dueToday);
    },
  );

  test('el dueño ve cuadres por revisar y préstamos nuevos', () async {
    final s = await service(as: owner);
    final kinds = s.notifications.map((n) => n.kind).toSet();
    expect(kinds, contains(NotificationKind.closingPending));
    // Préstamos de ejemplo los registró el dueño: no se notifica a sí mismo.
    expect(kinds, isNot(contains(NotificationKind.newLoan)));

    final pending = Get.find<ClosingRepository>().closings.first;
    await Get.find<ClosingRepository>().approve(pending);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(
      s.notifications.any((n) => n.id == 'pending-${pending.id}'),
      isFalse,
    );
  });

  test('leer, marcar todo y la campana', () async {
    final store = MemoryStore();
    // Una empresa real (en la demo lo leído no se recuerda).
    final s = await service(
      store: store,
      as: const AppUser(
        uid: 'c1',
        username: 'pedro',
        name: 'Pedro Cobrador',
        role: UserRole.collector,
        companyId: 'acme',
      ),
    );
    final badge = Get.find<SessionService>().unreadNotifications;
    expect(badge.value, s.notifications.length);

    s.markRead(s.notifications.first);
    expect(s.unreadCount, s.notifications.length - 1);
    expect(badge.value, s.unreadCount);

    s.markAllRead();
    expect(badge.value, 0);

    // Lo leído se recuerda en el teléfono.
    final again = NotificationService(store: store)..onInit();
    expect(again.unreadCount, 0);
  });

  test('al cerrar sesión no hay notificaciones', () async {
    final s = await service();
    await Get.find<AuthService>().signOut();
    s.recompute();
    expect(s.notifications, isEmpty);
    expect(s.unreadCount, 0);
  });

  test('en la demo cada sesión empieza sin leer', () async {
    final store = MemoryStore();
    final s = await service(store: store); // empresa "demo"
    s.markAllRead();
    expect(s.unreadCount, 0);
    final again = NotificationService(store: store)..onInit();
    expect(again.unreadCount, again.notifications.length);
  });

  test('un abono que no cambia el atraso no vuelve a avisar', () async {
    final s = await service();
    s.markAllRead();
    final loans = Get.find<LoanRepository>();
    // Un pago parcial no cambia el número de cuotas vencidas: sigue leído.
    final n = s.notifications.firstWhere(
      (x) => x.kind == NotificationKind.overdue,
    );
    await loans.applyPayment(
      loan: loans.loanById(n.arguments! as String)!,
      amount: 1,
      method: PaymentMethod.cash,
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(
      s.isRead(
        s.notifications.firstWhere(
          (x) =>
              x.arguments == n.arguments && x.kind == NotificationKind.overdue,
        ),
      ),
      isTrue,
    );
  });
}
