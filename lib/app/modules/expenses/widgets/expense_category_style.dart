import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/expense.dart';

/// Icono de cada categoría de gasto.
extension ExpenseCategoryStyle on ExpenseCategory {
  IconData get icon => switch (this) {
    ExpenseCategory.fuel => LucideIcons.fuel,
    ExpenseCategory.food => LucideIcons.utensils,
    ExpenseCategory.transport => LucideIcons.bike,
    ExpenseCategory.phone => LucideIcons.smartphone,
    ExpenseCategory.office => LucideIcons.paperclip,
    ExpenseCategory.salary => LucideIcons.users,
    ExpenseCategory.rent => LucideIcons.house,
    ExpenseCategory.other => LucideIcons.receipt,
  };
}
