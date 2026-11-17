import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:swiftloans/app/core/services/auth_backend.dart';
import 'package:swiftloans/app/core/services/auth_service.dart';
import 'package:swiftloans/app/core/services/key_value_store.dart';
import 'package:swiftloans/app/data/models/app_user.dart';

void main() {
  const root = AppUser(
    uid: 'u-root',
    username: 'root',
    name: 'ROOT',
    role: UserRole.root,
    mustChangePassword: true,
  );
  const inactive = AppUser(
    uid: 'u-off',
    username: 'viejo',
    name: 'Cobrador Viejo',
    role: UserRole.collector,
    active: false,
  );

  late FakeAuthBackend backend;
  late MemoryStore store;
  late AuthService auth;

  setUp(() {
    Get.testMode = true;
    backend = FakeAuthBackend(
      users: {
        'root@${AuthService.usernameDomain}': ('Temporal123', root),
        'viejo@${AuthService.usernameDomain}': ('clave1234', inactive),
      },
    );
    store = MemoryStore();
    auth = AuthService(backend: backend, store: store);
  });

  test('usuario sin @ se convierte en correo interno', () {
    expect(
      AuthService.emailFor(' ROOT '),
      'root@${AuthService.usernameDomain}',
    );
    expect(AuthService.emailFor('Ana@Mail.com'), 'ana@mail.com');
  });

  test('entra con usuario y recuerda el nombre', () async {
    final user = await auth.signIn(
      identifier: 'root',
      password: 'Temporal123',
      remember: true,
    );
    expect(user.isRoot, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.rememberedUsername, 'root');
  });

  test('contraseña incorrecta da un mensaje claro', () async {
    expect(
      () => auth.signIn(identifier: 'root', password: 'x', remember: true),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Usuario o contraseña incorrectos.',
        ),
      ),
    );
  });

  test('usuario inactivo no puede entrar', () async {
    await expectLater(
      auth.signIn(identifier: 'viejo', password: 'clave1234', remember: true),
      throwsA(isA<AuthFailure>()),
    );
    expect(auth.isLoggedIn, isFalse);
    expect(backend.currentUid, isNull);
  });

  test('sin "Recordarme" la sesión no se restaura al reabrir', () async {
    await auth.signIn(
      identifier: 'root',
      password: 'Temporal123',
      remember: false,
    );
    expect(auth.rememberedUsername, '');

    final reopened = AuthService(backend: backend, store: store);
    await reopened.restore();
    expect(reopened.isLoggedIn, isFalse);
  });

  test('con "Recordarme" la sesión se restaura al reabrir', () async {
    await auth.signIn(
      identifier: 'root',
      password: 'Temporal123',
      remember: true,
    );

    final reopened = AuthService(backend: backend, store: store);
    await reopened.restore();
    expect(reopened.user.value?.username, 'root');
  });

  test('cambiar la contraseña temporal quita la obligación', () async {
    await auth.signIn(
      identifier: 'root',
      password: 'Temporal123',
      remember: true,
    );
    expect(auth.user.value!.mustChangePassword, isTrue);

    await auth.changePassword('Temporal123', 'NuevaClave2026');
    expect(auth.user.value!.mustChangePassword, isFalse);

    await auth.signOut();
    await auth.signIn(
      identifier: 'root',
      password: 'NuevaClave2026',
      remember: true,
    );
    expect(auth.user.value!.mustChangePassword, isFalse);
  });

  test('iniciales del usuario', () {
    expect(root.initials, 'RO');
    expect(inactive.initials, 'CV');
  });
}
