import 'package:equatable/equatable.dart';

import '../../../core/models/account_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../budgets/cubit/budget_state.dart';
import '../../reports/cubit/report_state.dart';

/// Total income & expense untuk satu bulan kalender — dipakai oleh
/// [DashboardLoaded] untuk perbandingan bulan ini vs bulan lalu.
class MonthSummary extends Equatable {
  final double income;
  final double expense;

  const MonthSummary({required this.income, required this.expense});

  static const empty = MonthSummary(income: 0, expense: 0);

  @override
  List<Object?> get props => [income, expense];
}

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<AccountModel> accounts;
  final double totalBalance;
  final double monthIncome;
  final double monthExpense;
  final List<TransactionModel> recentTransactions;
  final double todayExpense;

  // Statistik tambahan untuk stats carousel di dashboard.
  final List<CategorySpend> categoryBreakdown;
  final List<DailyTotal> weekTrend;
  final MonthSummary lastMonth;
  final List<BudgetWithProgress> budgetProgress;

  const DashboardLoaded({
    required this.accounts,
    required this.totalBalance,
    required this.monthIncome,
    required this.monthExpense,
    required this.recentTransactions,
    required this.todayExpense,
    this.categoryBreakdown = const [],
    this.weekTrend = const [],
    this.lastMonth = MonthSummary.empty,
    this.budgetProgress = const [],
  });

  double get availableToSpend => totalBalance;
  double get monthNet => monthIncome - monthExpense;

  MonthSummary get thisMonth =>
      MonthSummary(income: monthIncome, expense: monthExpense);

  @override
  List<Object?> get props => [
        accounts,
        totalBalance,
        monthIncome,
        monthExpense,
        recentTransactions,
        todayExpense,
        categoryBreakdown,
        weekTrend,
        lastMonth,
        budgetProgress,
      ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
