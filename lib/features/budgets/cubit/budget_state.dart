import 'package:equatable/equatable.dart';

import '../../../core/models/category_model.dart';

class BudgetWithProgress extends Equatable {
  final int id;
  final CategoryModel category;
  final double amountLimit;
  final double spent;
  final int month;
  final int year;

  double get percentage => amountLimit > 0 ? (spent / amountLimit * 100) : 0;
  double get remaining => amountLimit - spent;
  bool get isOverBudget => spent > amountLimit;
  bool get isNearLimit => percentage >= 75 && !isOverBudget;

  const BudgetWithProgress({
    required this.id,
    required this.category,
    required this.amountLimit,
    required this.spent,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [id, category.id, amountLimit, spent, month, year];
}

sealed class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

class BudgetLoaded extends BudgetState {
  final List<BudgetWithProgress> budgets;
  final int month;
  final int year;

  double get totalLimit => budgets.fold(0, (s, b) => s + b.amountLimit);
  double get totalSpent => budgets.fold(0, (s, b) => s + b.spent);
  double get totalRemaining => totalLimit - totalSpent;

  const BudgetLoaded({
    required this.budgets,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [budgets, month, year];
}

class BudgetSaving extends BudgetState {
  const BudgetSaving();
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
  @override
  List<Object?> get props => [message];
}
