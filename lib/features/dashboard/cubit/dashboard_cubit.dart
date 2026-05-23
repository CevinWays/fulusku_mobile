import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/account_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../budgets/cubit/budget_state.dart';
import '../../reports/cubit/report_state.dart';
import '../datasource/dashboard_datasource.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardDatasource _datasource;

  DashboardCubit(this._datasource) : super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());
    try {
      // Parallel fetch — 7 round-trips in a single Future.wait.
      final results = await Future.wait([
        _datasource.getAccounts(),
        _datasource.getRecentTransactions(limit: 5),
        _datasource.getMonthSummary(),
        _datasource.getMonthlyCategoryBreakdown(),
        _datasource.getLastWeekTrend(),
        _datasource.getLastMonthSummary(),
        _datasource.getTopBudgetProgress(limit: 3),
      ]);

      final accounts = (results[0] as List).cast<AccountModel>();
      final recent = (results[1] as List).cast<TransactionModel>();
      final summary = results[2] as Map<String, double>;
      final categoryBreakdown = (results[3] as List).cast<CategorySpend>();
      final weekTrend = (results[4] as List).cast<DailyTotal>();
      final lastMonth = results[5] as MonthSummary;
      final budgetProgress =
          (results[6] as List).cast<BudgetWithProgress>();

      final totalBalance = accounts.fold<double>(
        0,
        (sum, a) => sum + ((a as dynamic).currentBalance ?? 0),
      );

      emit(DashboardLoaded(
        accounts: accounts,
        totalBalance: totalBalance,
        monthIncome: summary['income'] ?? 0,
        monthExpense: summary['expense'] ?? 0,
        recentTransactions: recent,
        todayExpense: summary['today_expense'] ?? 0,
        categoryBreakdown: categoryBreakdown,
        weekTrend: weekTrend,
        lastMonth: lastMonth,
        budgetProgress: budgetProgress,
      ));
    } catch (e) {
      emit(DashboardError('Gagal memuat dashboard: $e'));
    }
  }
}
