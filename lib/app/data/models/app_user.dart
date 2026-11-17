enum UserRole {
  /// Dueño de la plataforma: crea empresas y ve todo. Solo existe uno.
  root('ROOT'),

  /// Dueño de una empresa. Lo crea el ROOT junto con la empresa.
  owner('Dueño'),
  admin('Administrador'),
  collector('Cobrador');

  const UserRole(this.label);
  final String label;

  bool get managesUsers => this == owner || this == admin;

  /// Roles que este rol puede crear dentro de su empresa.
  List<UserRole> get canCreate => switch (this) {
    owner => const [admin, collector],
    admin => const [collector],
    _ => const [],
  };

  static UserRole parse(Object? value) => UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.collector,
  );
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.username,
    required this.name,
    required this.role,
    this.companyId,
    this.active = true,
    this.mustChangePassword = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) => AppUser(
    uid: uid,
    username: data['username'] as String? ?? '',
    name: data['name'] as String? ?? '',
    role: UserRole.parse(data['role']),
    companyId: data['companyId'] as String?,
    active: data['active'] as bool? ?? false,
    mustChangePassword: data['mustChangePassword'] as bool? ?? false,
  );

  final String uid;
  final String username;
  final String name;
  final UserRole role;

  /// Empresa a la que pertenece (null solo para el ROOT).
  final String? companyId;
  final bool active;

  /// Contraseña temporal: debe cambiarla al entrar.
  final bool mustChangePassword;

  bool get isRoot => role == UserRole.root;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) {
      return username.isEmpty ? '?' : username[0].toUpperCase();
    }
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Map<String, dynamic> toMap() => {
    'username': username,
    'name': name,
    'role': role.name,
    'companyId': companyId,
    'active': active,
    'mustChangePassword': mustChangePassword,
  };

  AppUser copyWith({bool? mustChangePassword, bool? active}) => AppUser(
    uid: uid,
    username: username,
    name: name,
    role: role,
    companyId: companyId,
    active: active ?? this.active,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );
}
