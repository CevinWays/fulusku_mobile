import 'package:equatable/equatable.dart';

import '../../../core/models/category_model.dart';
import '../../../core/models/transaction_model.dart';

class DailyTotal extends Equatable {
  final DateTime date;
  final double expense;
  final double income;
  const DailyTotal({required this.date, required this.expense, required this.income});
  @override
  List<Object?> get props => [date, expense, income];
}

class CategorySpend extends Equatable {
  final CategoryModel category;
  final double amount;
  const CategorySpend(this.category, this.amount);
  @override
  List<Object?> get props => [category.id, amount];
}

class BudgetProgress extends Equatable {
  final CategoryModel category;
  final double budgetLimit;
  final double spent;

  double get percentage => budgetLimit > 0 ? (spent / budgetLimit * 100) : 0;
  bool get isOverBudget => spent > budgetLimit;

  const BudgetProgress({
    required this.category,
    required this.budgetLimit,
    required this.spent,
  });

  @override
  List<Object?> get props => [category.id, budgetLimit, spent];
}

sealed class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class DailyReportLoaded extends ReportState {
  final DateTime date;
  final double availableToSpend;
  final double todayIncome;
  final double todayExpense;
  final List<TransactionModel> todayTransactions;

  const DailyReportLoaded({
    required this.date,
    required this.availableToSpend,
    required this.todayIncome,
    required this.todayExpense,
    required this.todayTransactions,
  });

  @override
  List<Object?> get props =>
      [date, availableToSpend, todayIncome, todayExpense, todayTransactions];
}

class MonthlyReportLoaded extends ReportState {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final List<CategorySpend> categoryBreakdown;
  final List<DailyTotal> dailyTrend;
  final List<BudgetProgress> budgetVsActual;

  double get savingRate =>
      totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100) : 0;

  double get net => totalIncome - totalExpense;

  const MonthlyReportLoaded({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.categoryBreakdown,
    required this.dailyTrend,
    required this.budgetVsActual,
  });

  @override
  List<Object?> get props => [
        year,
        month,
        totalIncome,
        totalExpense,
        categoryBreakdown,
        dailyTrend,
        budgetVsActual,
      ];
}

class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
  @override
  List<Object?> get props => [message];
}
