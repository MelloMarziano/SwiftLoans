import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';
import '../../core/services/auth_backend.dart';
import '../../core/services/auth_service.dart';
import '../models/app_user.dart';
import '../models/company.dart';

/// Empresas y usuarios. Las reglas de Firestore son las que de verdad
/// impiden que alguien que no sea ROOT cree empresas o se pase del límite de
/// usuarios; la app solo muestra las opciones permitidas.
abstract class AdminRepository {
  Stream<List<Company>> watchCompanies();
  Stream<Company?> watchCompany(String companyId);
  Stream<List<AppUser>> watchUsers(String companyId);
  Stream<List<CompanyClientRow>> watchClients(String companyId);
  Future<CompanyStats> stats(String companyId);

  /// Solo ROOT: crea la empresa y su usuario dueño.
  Future<Company> createCompany({
    required String name,
    String? rnc,
    String? phone,
    required int maxUsers,
    required NewUser owner,
  });

  /// Solo ROOT: suspender/activar y cambiar el límite de usuarios.
  Future<void> updateCompany(String companyId, {bool? active, int? maxUsers});

  /// Dueño o administrador: crea un empleado dentro de su empresa.
  Future<AppUser> createUser({
    required String companyId,
    required NewUser user,
  });

  Future<void> setUserActive(String uid, {required bool active});
}

class FirestoreAdminRepository implements AdminRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _companies =>
      _db.collection('companies');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Stream<List<Company>> watchCompanies() => _companies
      .orderBy('name')
      .snapshots()
      .map((s) => [for (final d in s.docs) _company(d.id, d.data())]);

  @override
  Stream<Company?> watchCompany(String companyId) => _companies
      .doc(companyId)
      .snapshots()
      .map((d) => d.data() == null ? null : _company(d.id, d.data()!));

  @override
  Stream<List<AppUser>> watchUsers(String companyId) => _users
      .where('companyId', isEqualTo: companyId)
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) AppUser.fromMap(d.id, d.data())]
              ..sort((a, b) => a.role.index.compareTo(b.role.index)),
      );

  @override
  Stream<List<CompanyClientRow>> watchClients(String companyId) => _companies
      .doc(companyId)
      .collection('clients')
      .orderBy('name')
      .limit(500)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            CompanyClientRow(
              id: d.id,
              name: d.data()['name'] as String? ?? '',
              document: d.data()['document'] as String?,
              balance: (d.data()['balance'] as num?)?.toDouble() ?? 0,
              active: d.data()['active'] as bool? ?? true,
            ),
        ],
      );

  @override
  Future<CompanyStats> stats(String companyId) async {
    // Se cuenta y suma en el servidor, sin descargar los clientes.
    final snap = await _companies
        .doc(companyId)
        .collection('clients')
        .aggregate(count(), sum('balance'))
        .get();
    return CompanyStats(
      clients: snap.count ?? 0,
      portfolio: snap.getSum('balance') ?? 0,
    );
  }

  @override
  Future<Company> createCompany({
    required String name,
    String? rnc,
    String? phone,
    required int maxUsers,
    required NewUser owner,
  }) async {
    final uid = await _createAuthUser(owner);
    final ref = _companies.doc();
    final company = Company(
      id: ref.id,
      name: name,
      rnc: rnc,
      phone: phone,
      ownerUid: uid,
      ownerName: owner.name,
      maxUsers: maxUsers,
      userCount: 1,
    );

    await (_db.batch()
          ..set(ref, {
            ...company.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..set(_users.doc(uid), _profile(uid, owner, ref.id)))
        .commit();
    return company;
  }

  @override
  Future<void> updateCompany(String companyId, {bool? active, int? maxUsers}) =>
      _companies.doc(companyId).update({
        'active': ?active,
        'maxUsers': ?maxUsers,
      });

  @override
  Future<AppUser> createUser({
    required String companyId,
    required NewUser user,
  }) async {
    // Se revisa el cupo antes de crear la cuenta, para no dejar cuentas
    // sueltas si la empresa ya está llena.
    final company = await _companies.doc(companyId).get();
    final data = company.data();
    if (data == null) throw const AuthFailure('La empresa no existe.');
    final used = (data['userCount'] as num?)?.toInt() ?? 0;
    final max = (data['maxUsers'] as num?)?.toInt() ?? 0;
    if (used >= max) {
      throw AuthFailure(
        'Llegaste al límite de $max usuarios. Contacta a SwiftLoans para ampliarlo.',
      );
    }

    final uid = await _createAuthUser(user);
    try {
      await (_db.batch()
            ..set(_users.doc(uid), _profile(uid, user, companyId))
            ..update(_companies.doc(companyId), {'userCount': used + 1}))
          .commit();
    } on FirebaseException catch (e) {
      throw AuthFailure(
        e.code == 'permission-denied'
            ? 'No tienes permiso para crear este usuario.'
            : 'No se pudo guardar el usuario (${e.code}).',
      );
    }
    return AppUser.fromMap(uid, _profile(uid, user, companyId));
  }

  @override
  Future<void> setUserActive(String uid, {required bool active}) =>
      _users.doc(uid).update({'active': active});

  /// Crea la cuenta en Firebase Auth usando una instancia secundaria, para no
  /// cerrar la sesión de quien la está creando.
  Future<String> _createAuthUser(NewUser user) async {
    final app = await _secondaryApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    try {
      final result = await auth.createUserWithEmailAndPassword(
        email: AuthService.emailFor(user.username),
        password: user.password,
      );
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(switch (e.code) {
        'email-already-in-use' => 'El usuario "${user.username}" ya existe.',
        'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
        'invalid-email' => 'El nombre de usuario no es válido.',
        _ => 'No se pudo crear el usuario (${e.code}).',
      });
    } finally {
      await auth.signOut();
    }
  }

  static Future<FirebaseApp> _secondaryApp() async {
    const name = 'user-admin';
    for (final app in Firebase.apps) {
      if (app.name == name) return app;
    }
    return Firebase.initializeApp(
      name: name,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Map<String, dynamic> _profile(
    String uid,
    NewUser user,
    String companyId,
  ) => {
    'username': user.username.trim().toLowerCase(),
    'name': user.name.trim(),
    'role': user.role.name,
    'companyId': companyId,
    'active': true,
    'mustChangePassword': true,
  };

  static Company _company(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return Company.fromMap(id, {
      ...data,
      'createdAt': created is Timestamp ? created.toDate() : null,
    });
  }
}

/// Versión en memoria para tests y vistas previas. Aplica las mismas reglas
/// de negocio que las reglas de Firestore (cupo de usuarios, roles).
class InMemoryAdminRepository implements AdminRepository {
  InMemoryAdminRepository({List<Company>? companies, List<AppUser>? users}) {
    _companies.addAll({for (final c in companies ?? <Company>[]) c.id: c});
    _users.addAll({for (final u in users ?? <AppUser>[]) u.uid: u});
  }

  final _companies = <String, Company>{};
  final _users = <String, AppUser>{};
  final clients = <String, List<CompanyClientRow>>{};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 1;

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<Company>> watchCompanies() => _watch(
    () => _companies.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
  );

  @override
  Stream<Company?> watchCompany(String companyId) =>
      _watch(() => _companies[companyId]);

  @override
  Stream<List<AppUser>> watchUsers(String companyId) => _watch(
    () =>
        _users.values.where((u) => u.companyId == companyId).toList()
          ..sort((a, b) => a.role.index.compareTo(b.role.index)),
  );

  @override
  Stream<List<CompanyClientRow>> watchClients(String companyId) =>
      _watch(() => clients[companyId] ?? const []);

  @override
  Future<CompanyStats> stats(String companyId) async {
    final rows = clients[companyId] ?? const [];
    return CompanyStats(
      clients: rows.length,
      portfolio: rows.fold(0, (s, c) => s + c.balance),
    );
  }

  @override
  Future<Company> createCompany({
    required String name,
    String? rnc,
    String? phone,
    required int maxUsers,
    required NewUser owner,
  }) async {
    final id = 'c${_nextId++}';
    final uid = _addUser(owner, id);
    final company = Company(
      id: id,
      name: name,
      rnc: rnc,
      phone: phone,
      ownerUid: uid,
      ownerName: owner.name,
      maxUsers: maxUsers,
      userCount: 1,
    );
    _companies[id] = company;
    _changes.add(null);
    return company;
  }

  @override
  Future<void> updateCompany(
    String companyId, {
    bool? active,
    int? maxUsers,
  }) async {
    final c = _companies[companyId]!;
    _companies[companyId] = c.copyWith(active: active, maxUsers: maxUsers);
    _changes.add(null);
  }

  @override
  Future<AppUser> createUser({
    required String companyId,
    required NewUser user,
  }) async {
    final c = _companies[companyId];
    if (c == null) throw const AuthFailure('La empresa no existe.');
    if (!c.hasFreeSeats) {
      throw AuthFailure(
        'Llegaste al límite de ${c.maxUsers} usuarios. Contacta a SwiftLoans para ampliarlo.',
      );
    }
    final uid = _addUser(user, companyId);
    _companies[companyId] = c.copyWith(userCount: c.userCount + 1);
    _changes.add(null);
    return _users[uid]!;
  }

  @override
  Future<void> setUserActive(String uid, {required bool active}) async {
    _users[uid] = _users[uid]!.copyWith(active: active);
    _changes.add(null);
  }

  String _addUser(NewUser user, String companyId) {
    final username = user.username.trim().toLowerCase();
    if (_users.values.any((u) => u.username == username)) {
      throw AuthFailure('El usuario "${user.username}" ya existe.');
    }
    final uid = 'u${_nextId++}';
    _users[uid] = AppUser(
      uid: uid,
      username: username,
      name: user.name.trim(),
      role: user.role,
      companyId: companyId,
      mustChangePassword: true,
    );
    return uid;
  }
}
