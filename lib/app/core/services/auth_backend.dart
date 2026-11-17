import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/app_user.dart';

/// Error de autenticación con mensaje listo para mostrar.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Operaciones de autenticación. En la app es Firebase; en los tests, memoria.
abstract class AuthBackend {
  String? get currentUid;
  Future<String> signIn(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<AppUser?> loadProfile(String uid);
  Future<void> clearMustChangePassword(String uid);

  /// false si la empresa fue suspendida por el ROOT (o no existe).
  Future<bool> isCompanyActive(String companyId);
}

class FirebaseAuthBackend implements AuthBackend {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<String> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthFailure('Tu sesión expiró. Vuelve a iniciar sesión.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        ),
      );
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<AppUser?> loadProfile(String uid) async {
    // get() usa la caché si no hay conexión, para cobradores sin señal.
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return data == null ? null : AppUser.fromMap(uid, data);
  }

  @override
  Future<void> clearMustChangePassword(String uid) =>
      _db.collection('users').doc(uid).update({'mustChangePassword': false});

  @override
  Future<bool> isCompanyActive(String companyId) async {
    try {
      final doc = await _db.collection('companies').doc(companyId).get();
      return doc.data()?['active'] == true;
    } on FirebaseException {
      // Las reglas niegan la lectura si la empresa está suspendida.
      return false;
    }
  }

  static String _message(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' => 'Usuario o contraseña incorrectos.',
    'user-disabled' => 'Este usuario está deshabilitado.',
    'too-many-requests' =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
    'network-request-failed' => 'Sin conexión. Revisa tu internet.',
    'weak-password' => 'La contraseña es muy débil.',
    'requires-recent-login' => 'Vuelve a iniciar sesión para continuar.',
    _ => 'No se pudo completar la operación ($code).',
  };
}

/// Backend en memoria para tests y vistas previas.
class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend({
    Map<String, (String, AppUser)>? users,
    String? signedInUid,
    this.suspendedCompanies = const {},
  }) : _users = users ?? {},
       _uid = signedInUid;

  /// Empresas suspendidas (para probar el bloqueo de acceso).
  final Set<String> suspendedCompanies;

  /// Sesión iniciada como ROOT (para las vistas previas de la app).
  factory FakeAuthBackend.signedInRoot() {
    const root = AppUser(
      uid: 'root',
      username: 'root',
      name: 'Francisco',
      role: UserRole.root,
    );
    return FakeAuthBackend(
      users: {'root@swiftloans-app.firebaseapp.com': ('root1234', root)},
      signedInUid: 'root',
    );
  }

  /// email -> (contraseña, perfil)
  final Map<String, (String, AppUser)> _users;
  String? _uid;

  @override
  String? get currentUid => _uid;

  @override
  Future<String> signIn(String email, String password) async {
    final entry = _users[email];
    if (entry == null || entry.$1 != password) {
      throw const AuthFailure('Usuario o contraseña incorrectos.');
    }
    return _uid = entry.$2.uid;
  }

  @override
  Future<void> signOut() async => _uid = null;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final key = _users.keys.firstWhere((k) => _users[k]!.$2.uid == _uid);
    if (_users[key]!.$1 != currentPassword) {
      throw const AuthFailure('Usuario o contraseña incorrectos.');
    }
    _users[key] = (newPassword, _users[key]!.$2);
  }

  @override
  Future<AppUser?> loadProfile(String uid) async =>
      _users.values.map((e) => e.$2).where((u) => u.uid == uid).firstOrNull;

  @override
  Future<bool> isCompanyActive(String companyId) async =>
      !suspendedCompanies.contains(companyId);

  @override
  Future<void> clearMustChangePassword(String uid) async {
    final key = _users.keys.firstWhere((k) => _users[k]!.$2.uid == uid);
    _users[key] = (
      _users[key]!.$1,
      _users[key]!.$2.copyWith(mustChangePassword: false),
    );
  }
}
