import 'package:intl/intl.dart';

enum ClosingStatus {
  pending('Por revisar'),
  approved('Revisado');

  const ClosingStatus(this.label);
  final String label;
}

/// Billetes y monedas de RD$ para contar la caja.
abstract class Denominations {
  static const bills = [2000, 1000, 500, 200, 100, 50];
  static const coins = [25, 10, 5, 1];
  static const all = [...bills, ...coins];
}

/// Cuadre de caja de un usuario en un día. Una vez cerrado no se edita;
/// el dueño/administrador solo lo marca como revisado.
class CashClosing {
  const CashClosing({
    required this.id,
    required this.day,
    required this.byUid,
    required this.byName,
    required this.openingCash,
    required this.cashIn,
    required this.transferIn,
    required this.cashLoans,
    required this.cashExpenses,
    required this.counted,
    required this.createdAt,
    this.paymentsCount = 0,
    this.denominations = const {},
    this.notes,
    this.status = ClosingStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory CashClosing.fromMap(String id, Map<String, dynamic> d) => CashClosing(
    id: id,
    day: d['day'] as DateTime,
    byUid: d['byUid'] as String? ?? '',
    byName: d['byName'] as String? ?? '',
    openingCash: _num(d['openingCash']),
    cashIn: _num(d['cashIn']),
    transferIn: _num(d['transferIn']),
    cashLoans: _num(d['cashLoans']),
    cashExpenses: _num(d['cashExpenses']),
    counted: _num(d['counted']),
    paymentsCount: (d['paymentsCount'] as num?)?.toInt() ?? 0,
    denominations: {
      for (final e in ((d['denominations'] as Map?) ?? const {}).entries)
        int.parse('${e.key}'): (e.value as num).toInt(),
    },
    notes: d['notes'] as String?,
    status:
        ClosingStatus.values.asNameMap()[d['status']] ?? ClosingStatus.pending,
    reviewedBy: d['reviewedBy'] as String?,
    reviewedAt: d['reviewedAt'] as DateTime?,
    createdAt: d['createdAt'] as DateTime? ?? d['day'] as DateTime,
  );

  /// Un cuadre por usuario y día: "C-20261116-uid".
  static String idFor(String uid, DateTime day) =>
      'C-${DateFormat('yyyyMMdd').format(day)}-$uid';

  final String id;

  /// Día del cuadre (sin hora).
  final DateTime day;
  final String byUid;
  final String byName;

  /// Efectivo con el que salió (fondo / cambio).
  final double openingCash;
  final double cashIn;
  final double transferIn;
  final double cashLoans;
  final double cashExpenses;
  final double counted;
  final int paymentsCount;

  /// Cantidad de cada billete/moneda contada (vacío si se ingresó el total).
  final Map<int, int> denominations;
  final String? notes;
  final ClosingStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  /// Lo que debería tener en mano.
  double get expected => openingCash + cashIn - cashLoans - cashExpenses;

  /// Positivo = sobrante, negativo = faltante.
  double get difference => _round(counted - expected);

  Map<String, dynamic> toMap() => {
    'day': day,
    'byUid': byUid,
    'byName': byName,
    'openingCash': openingCash,
    'cashIn': cashIn,
    'transferIn': transferIn,
    'cashLoans': cashLoans,
    'cashExpenses': cashExpenses,
    'counted': counted,
    'paymentsCount': paymentsCount,
    'denominations': {
      for (final e in denominations.entries)
        if (e.value > 0) '${e.key}': e.value,
    },
    if (notes != null) 'notes': notes,
    'status': status.name,
    'createdAt': createdAt,
  };

  static double _num(Object? v) => (v as num?)?.toDouble() ?? 0;
  static double _round(double v) => (v * 100).roundToDouble() / 100;
}

/// Sobrante / faltante / cuadrado según la diferencia.
enum ClosingBalance {
  even('Cuadrado'),
  over('Sobrante'),
  short('Faltante');

  const ClosingBalance(this.label);
  final String label;

  static ClosingBalance of(double difference) => difference.abs() < 0.01
      ? even
      : difference > 0
      ? over
      : short;
}

/// Fondo inicial (efectivo para cambio) que el dueño/administrador le
/// asigna a un usuario para un día.
class CashFund {
  const CashFund({
    required this.id,
    required this.day,
    required this.uid,
    required this.name,
    required this.amount,
    required this.assignedBy,
    required this.assignedAt,
  });

  factory CashFund.fromMap(String id, Map<String, dynamic> d) => CashFund(
    id: id,
    day: d['day'] as DateTime,
    uid: d['uid'] as String? ?? '',
    name: d['name'] as String? ?? '',
    amount: (d['amount'] as num?)?.toDouble() ?? 0,
    assignedBy: d['assignedBy'] as String? ?? '',
    assignedAt: d['assignedAt'] as DateTime? ?? d['day'] as DateTime,
  );

  /// Un fondo por usuario y día: "F-20261116-uid".
  static String idFor(String uid, DateTime day) =>
      'F-${DateFormat('yyyyMMdd').format(day)}-$uid';

  final String id;
  final DateTime day;
  final String uid;
  final String name;
  final double amount;
  final String assignedBy;
  final DateTime assignedAt;

  Map<String, dynamic> toMap() => {
    'day': day,
    'uid': uid,
    'name': name,
    'amount': amount,
    'assignedBy': assignedBy,
    'assignedAt': assignedAt,
  };
}
