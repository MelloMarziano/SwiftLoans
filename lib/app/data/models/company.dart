import 'app_user.dart';

/// Empresa cliente de SwiftLoans. Solo el ROOT las crea.
class Company {
  const Company({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.ownerName,
    this.rnc,
    this.phone,
    this.active = true,
    this.maxUsers = 5,
    this.userCount = 0,
    this.createdAt,
  });

  factory Company.fromMap(String id, Map<String, dynamic> data) => Company(
    id: id,
    name: data['name'] as String? ?? '',
    ownerUid: data['ownerUid'] as String? ?? '',
    ownerName: data['ownerName'] as String? ?? '',
    rnc: data['rnc'] as String?,
    phone: data['phone'] as String?,
    active: data['active'] as bool? ?? false,
    maxUsers: (data['maxUsers'] as num?)?.toInt() ?? 0,
    userCount: (data['userCount'] as num?)?.toInt() ?? 0,
    createdAt: data['createdAt'] is DateTime
        ? data['createdAt'] as DateTime
        : null,
  );

  final String id;
  final String name;
  final String ownerUid;
  final String ownerName;
  final String? rnc;
  final String? phone;

  /// Suspendida = ningún usuario de la empresa puede entrar.
  final bool active;

  /// Límite de usuarios (lo fija el ROOT). Incluye a los desactivados, para
  /// que no se puedan "rotar" cuentas.
  final int maxUsers;
  final int userCount;
  final DateTime? createdAt;

  bool get hasFreeSeats => userCount < maxUsers;
  int get freeSeats => (maxUsers - userCount).clamp(0, maxUsers);

  Map<String, dynamic> toMap() => {
    'name': name,
    'ownerUid': ownerUid,
    'ownerName': ownerName,
    'rnc': rnc,
    'phone': phone,
    'active': active,
    'maxUsers': maxUsers,
    'userCount': userCount,
  };

  Company copyWith({bool? active, int? maxUsers, int? userCount}) => Company(
    id: id,
    name: name,
    ownerUid: ownerUid,
    ownerName: ownerName,
    rnc: rnc,
    phone: phone,
    active: active ?? this.active,
    maxUsers: maxUsers ?? this.maxUsers,
    userCount: userCount ?? this.userCount,
    createdAt: createdAt,
  );
}

/// Resumen de clientes de una empresa (para el ROOT).
class CompanyStats {
  const CompanyStats({required this.clients, required this.portfolio});

  final int clients;

  /// Suma de lo que deben los clientes (saldo de cartera).
  final double portfolio;
}

/// Cliente tal como lo ve el ROOT en el detalle de una empresa.
class CompanyClientRow {
  const CompanyClientRow({
    required this.id,
    required this.name,
    required this.balance,
    this.document,
    this.active = true,
  });

  final String id;
  final String name;
  final String? document;
  final double balance;
  final bool active;
}

/// Datos para crear un usuario nuevo (dueño, administrador o cobrador).
class NewUser {
  const NewUser({
    required this.username,
    required this.name,
    required this.password,
    required this.role,
  });

  final String username;
  final String name;

  /// Contraseña temporal: se pide cambiarla al primer ingreso.
  final String password;
  final UserRole role;
}
