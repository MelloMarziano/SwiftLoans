import 'loan.dart';

enum ExpenseCategory {
  fuel('Combustible'),
  food('Comida'),
  transport('Transporte'),
  phone('Recargas'),
  office('Papelería'),
  salary('Salarios'),
  rent('Alquiler'),
  other('Otros');

  const ExpenseCategory(this.label);
  final String label;
}

/// Gasto del negocio (combustible, comida...). Es una salida de dinero y
/// queda firmado por quien lo registra.
class Expense {
  const Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.method,
    required this.byUid,
    required this.byName,
    this.description,
  });

  factory Expense.fromMap(String id, Map<String, dynamic> d) => Expense(
    id: id,
    date: d['date'] as DateTime,
    amount: (d['amount'] as num).toDouble(),
    category:
        ExpenseCategory.values.asNameMap()[d['category']] ??
        ExpenseCategory.other,
    method: PaymentMethod.values.asNameMap()[d['method']] ?? PaymentMethod.cash,
    byUid: d['byUid'] as String? ?? '',
    byName: d['byName'] as String? ?? '',
    description: d['description'] as String?,
  );

  /// Número del gasto, p. ej. "G-261116-0930-K7P" (se puede crear sin
  /// conexión).
  final String id;
  final DateTime date;
  final double amount;
  final ExpenseCategory category;
  final PaymentMethod method;
  final String byUid;
  final String byName;
  final String? description;

  /// Lo que se muestra como título: la descripción o la categoría.
  String get title =>
      (description?.trim().isNotEmpty ?? false) ? description! : category.label;

  Map<String, dynamic> toMap() => {
    'date': date,
    'amount': amount,
    'category': category.name,
    'method': method.name,
    'byUid': byUid,
    'byName': byName,
    if (description != null) 'description': description,
  };
}
