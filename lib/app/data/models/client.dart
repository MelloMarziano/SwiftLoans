/// Situación del cliente respecto a sus préstamos.
enum ClientLoanStatus {
  toCollect('Por cobrar'),
  upToDate('Al día'),
  overdue('Vencido'),
  none('Sin préstamo');

  const ClientLoanStatus(this.label);
  final String label;
}

class Client {
  const Client({
    required this.id,
    required this.name,
    this.alias,
    this.document,
    this.phone,
    this.phone2,
    this.occupation,
    this.address,
    this.sector,
    this.route = 'OFICINA',
    this.referenceName,
    this.referencePhone,
    this.notes,
    this.isActive = true,
    this.loanStatus = ClientLoanStatus.none,
    this.balance = 0,
    this.createdAt,
  });

  factory Client.fromMap(String id, Map<String, dynamic> d) => Client(
    id: id,
    name: d['name'] as String? ?? '',
    alias: d['alias'] as String?,
    document: d['document'] as String?,
    phone: d['phone'] as String?,
    phone2: d['phone2'] as String?,
    occupation: d['occupation'] as String?,
    address: d['address'] as String?,
    sector: d['sector'] as String?,
    route: d['route'] as String? ?? 'OFICINA',
    referenceName: d['referenceName'] as String?,
    referencePhone: d['referencePhone'] as String?,
    notes: d['notes'] as String?,
    isActive: d['active'] as bool? ?? true,
    balance: (d['balance'] as num?)?.toDouble() ?? 0,
    createdAt: d['createdAt'] as DateTime?,
  );

  final String id;
  final String name;

  /// Apodo con el que se conoce al cliente, p. ej. "El Marron".
  final String? alias;

  /// Cédula o documento de identidad.
  final String? document;
  final String? phone;
  final String? phone2;
  final String? occupation;
  final String? address;

  /// Sector o ciudad.
  final String? sector;

  /// Ruta de cobro u oficina a la que pertenece.
  final String route;
  final String? referenceName;
  final String? referencePhone;
  final String? notes;
  final bool isActive;

  /// Se calcula a partir de sus préstamos y la fecha de hoy; no se guarda.
  final ClientLoanStatus loanStatus;

  /// Lo que debe en capital + interés (sin mora). Se guarda para que el ROOT
  /// pueda sumar la cartera de cada empresa en el servidor.
  final double balance;
  final DateTime? createdAt;

  bool get hasLoan => loanStatus != ClientLoanStatus.none;

  String get displayName => alias == null ? name : '$name ($alias)';

  /// "Alexander Cueva" -> "AC"
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  /// Campos que se guardan en Firestore (el saldo se maneja aparte con
  /// incrementos, para no pisar pagos hechos desde otro teléfono).
  Map<String, dynamic> toMap() => {
    'name': name,
    'nameLower': name.toLowerCase(),
    'alias': alias,
    'document': document,
    'phone': phone,
    'phone2': phone2,
    'occupation': occupation,
    'address': address,
    'sector': sector,
    'route': route,
    'referenceName': referenceName,
    'referencePhone': referencePhone,
    'notes': notes,
    'active': isActive,
  };

  Client copyWith({
    String? name,
    String? alias,
    String? document,
    String? phone,
    String? phone2,
    String? occupation,
    String? address,
    String? sector,
    String? route,
    String? referenceName,
    String? referencePhone,
    String? notes,
    bool? isActive,
    ClientLoanStatus? loanStatus,
    double? balance,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      document: document ?? this.document,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      occupation: occupation ?? this.occupation,
      address: address ?? this.address,
      sector: sector ?? this.sector,
      route: route ?? this.route,
      referenceName: referenceName ?? this.referenceName,
      referencePhone: referencePhone ?? this.referencePhone,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      loanStatus: loanStatus ?? this.loanStatus,
      balance: balance ?? this.balance,
      createdAt: createdAt,
    );
  }
}
