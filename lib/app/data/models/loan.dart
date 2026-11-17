import 'loan_terms.dart';

/// Cómo se repartió un pago en una cuota.
class InstallmentAllocation {
  const InstallmentAllocation({
    required this.number,
    required this.lateFee,
    required this.interest,
    required this.capital,
    required this.completes,
  });

  factory InstallmentAllocation.fromMap(Map<String, dynamic> d) =>
      InstallmentAllocation(
        number: (d['number'] as num).toInt(),
        lateFee: (d['lateFee'] as num?)?.toDouble() ?? 0,
        interest: (d['interest'] as num?)?.toDouble() ?? 0,
        capital: (d['capital'] as num?)?.toDouble() ?? 0,
        completes: d['completes'] as bool? ?? false,
      );

  final int number;
  final double lateFee;
  final double interest;
  final double capital;

  /// La cuota quedó saldada con este pago.
  final bool completes;

  Map<String, dynamic> toMap() => {
    'number': number,
    'lateFee': lateFee,
    'interest': interest,
    'capital': capital,
    'completes': completes,
  };
}

enum PaymentMethod {
  cash('Efectivo'),
  transfer('Transferencia');

  const PaymentMethod(this.label);
  final String label;
}

/// Cuota de un préstamo con lo que se le ha pagado.
class LoanInstallment {
  const LoanInstallment({
    required this.number,
    required this.dueDate,
    required this.capital,
    required this.interest,
    this.paidLateFee = 0,
    this.paidInterest = 0,
    this.paidCapital = 0,
  });

  factory LoanInstallment.fromSchedule(Installment i) => LoanInstallment(
    number: i.number,
    dueDate: i.dueDate,
    capital: i.capital,
    interest: i.interest,
  );

  final int number;
  final DateTime dueDate;
  final double capital;
  final double interest;
  final double paidLateFee;
  final double paidInterest;
  final double paidCapital;

  double get payment => capital + interest;
  double get pendingInterest => _clamp(interest - paidInterest);
  double get pendingCapital => _clamp(capital - paidCapital);
  double get pending => pendingInterest + pendingCapital;
  bool get isPaid => pending == 0;

  LoanInstallment copyWith({
    double? paidLateFee,
    double? paidInterest,
    double? paidCapital,
  }) => LoanInstallment(
    number: number,
    dueDate: dueDate,
    capital: capital,
    interest: interest,
    paidLateFee: paidLateFee ?? this.paidLateFee,
    paidInterest: paidInterest ?? this.paidInterest,
    paidCapital: paidCapital ?? this.paidCapital,
  );

  /// Evita saldos de -0.000001 por errores de punto flotante.
  static double _clamp(double v) => v < 0.005 ? 0 : v;
}

class Loan {
  const Loan({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.frequency,
    required this.type,
    required this.monthlyRate,
    required this.lateFeeRate,
    required this.startDate,
    required this.installments,
    this.createdAt,
    this.createdByUid,
    this.createdBy,
  });

  /// El calendario se guarda tal cual se generó; lo pagado se calcula a partir
  /// de los pagos (ver LoanRepository).
  factory Loan.fromMap(String id, Map<String, dynamic> d) => Loan(
    id: id,
    clientId: d['clientId'] as String,
    amount: (d['amount'] as num).toDouble(),
    frequency: PaymentFrequency.values.byName(d['frequency'] as String),
    type: LoanType.values.byName(d['type'] as String),
    monthlyRate: (d['monthlyRate'] as num).toDouble(),
    lateFeeRate: (d['lateFeeRate'] as num?)?.toDouble() ?? 0,
    startDate: d['startDate'] as DateTime,
    createdAt: d['createdAt'] as DateTime?,
    createdByUid: d['createdByUid'] as String?,
    createdBy: d['createdBy'] as String?,
    installments: [
      for (final i in (d['installments'] as List).cast<Map<String, dynamic>>())
        LoanInstallment(
          number: (i['number'] as num).toInt(),
          dueDate: i['dueDate'] as DateTime,
          capital: (i['capital'] as num).toDouble(),
          interest: (i['interest'] as num).toDouble(),
        ),
    ],
  );

  final String id;
  final String clientId;

  /// Monto financiado.
  final double amount;
  final PaymentFrequency frequency;
  final LoanType type;
  final double monthlyRate;

  /// % de mora que se cobra una vez sobre cada cuota vencida.
  final double lateFeeRate;
  final DateTime startDate;
  final List<LoanInstallment> installments;
  final DateTime? createdAt;

  /// Usuario que registró el préstamo (null en préstamos anteriores).
  final String? createdByUid;
  final String? createdBy;

  /// Capital + interés de todas las cuotas.
  double get totalDue => installments.fold(0, (s, i) => s + i.payment);

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'amount': amount,
    'frequency': frequency.name,
    'type': type.name,
    'monthlyRate': monthlyRate,
    'lateFeeRate': lateFeeRate,
    'startDate': startDate,
    if (createdByUid != null) 'createdByUid': createdByUid,
    if (createdBy != null) 'createdBy': createdBy,
    'installments': [
      for (final i in installments)
        {
          'number': i.number,
          'dueDate': i.dueDate,
          'capital': i.capital,
          'interest': i.interest,
        },
    ],
  };

  bool get isPaidOff => installments.every((i) => i.isPaid);

  Loan withInstallments(List<LoanInstallment> updated) => Loan(
    id: id,
    clientId: clientId,
    amount: amount,
    frequency: frequency,
    type: type,
    monthlyRate: monthlyRate,
    lateFeeRate: lateFeeRate,
    startDate: startDate,
    installments: updated,
    createdAt: createdAt,
    createdByUid: createdByUid,
    createdBy: createdBy,
  );

  Loan withId(String newId) => Loan(
    id: newId,
    clientId: clientId,
    amount: amount,
    frequency: frequency,
    type: type,
    monthlyRate: monthlyRate,
    lateFeeRate: lateFeeRate,
    startDate: startDate,
    installments: installments,
    createdAt: createdAt,
    createdByUid: createdByUid,
    createdBy: createdBy,
  );

  /// El préstamo firmado por quien lo registra.
  Loan withAuthor({required String uid, required String name}) => Loan(
    id: id,
    clientId: clientId,
    amount: amount,
    frequency: frequency,
    type: type,
    monthlyRate: monthlyRate,
    lateFeeRate: lateFeeRate,
    startDate: startDate,
    installments: installments,
    createdAt: createdAt,
    createdByUid: uid,
    createdBy: name,
  );
}

/// Pago aplicado a un préstamo (lo que se imprime en el recibo).
class Payment {
  const Payment({
    required this.id,
    required this.loanId,
    required this.clientId,
    required this.date,
    required this.amount,
    required this.method,
    required this.lateFee,
    required this.interest,
    required this.capital,
    required this.installmentsCompleted,
    required this.balanceAfter,
    required this.collector,
    this.collectorUid,
    this.allocations = const [],
  });

  factory Payment.fromMap(String id, Map<String, dynamic> d) => Payment(
    id: id,
    loanId: d['loanId'] as String,
    clientId: d['clientId'] as String,
    date: d['date'] as DateTime,
    amount: (d['amount'] as num).toDouble(),
    method: PaymentMethod.values.byName(d['method'] as String),
    lateFee: (d['lateFee'] as num?)?.toDouble() ?? 0,
    interest: (d['interest'] as num?)?.toDouble() ?? 0,
    capital: (d['capital'] as num?)?.toDouble() ?? 0,
    installmentsCompleted: [
      for (final n in (d['installmentsCompleted'] as List? ?? const []))
        (n as num).toInt(),
    ],
    balanceAfter: (d['balanceAfter'] as num?)?.toDouble() ?? 0,
    collector: d['collector'] as String? ?? '',
    collectorUid: d['collectorUid'] as String?,
    allocations: [
      for (final a
          in (d['allocations'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
        InstallmentAllocation.fromMap(a),
    ],
  );

  /// Número de recibo, p. ej. "R-000124".
  final String id;
  final String loanId;
  final String clientId;
  final DateTime date;
  final double amount;
  final PaymentMethod method;
  final double lateFee;
  final double interest;
  final double capital;

  /// Cuotas que quedaron saldadas con este pago.
  final List<int> installmentsCompleted;

  /// Saldo pendiente del préstamo después del pago (incluye mora).
  final double balanceAfter;
  final String collector;

  /// Usuario que cobró (null en pagos anteriores a este campo).
  final String? collectorUid;

  /// Cómo se repartió en cada cuota. Con esto se reconstruye lo pagado de
  /// cada préstamo, sin editar nunca el préstamo.
  final List<InstallmentAllocation> allocations;

  Map<String, dynamic> toMap() => {
    'loanId': loanId,
    'clientId': clientId,
    'date': date,
    'amount': amount,
    'method': method.name,
    'lateFee': lateFee,
    'interest': interest,
    'capital': capital,
    'installmentsCompleted': installmentsCompleted,
    'balanceAfter': balanceAfter,
    'collector': collector,
    if (collectorUid != null) 'collectorUid': collectorUid,
    'allocations': [for (final a in allocations) a.toMap()],
  };
}
