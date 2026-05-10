import 'package:flutter_bloc/flutter_bloc.dart';

import '../datasource/dashboard_datasource.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardDatasource _datasource;

  DashboardCubit(this._datasource) : super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());
    try {
      // Parallel fetch
      final results = await Future.wait([
        _datasource.getAccounts(),
        _datasource.getRecentTransactions(limit: 5),
        _datasource.getMonthSummary(),
      ]);

      final accounts = results[0] as List;
      final recent = results[1] as List;
      final summary = results[2] as Map<String, double>;

      final totalBalance = accounts.fold<double>(
        0,
        (sum, a) => sum + ((a as dynamic).currentBalance ?? 0),
      );

      emit(DashboardLoaded(
        accounts: accounts.cast(),
        totalBalance: totalBalance,
        monthIncome: summary['income'] ?? 0,
        monthExpense: summary['expense'] ?? 0,
        recentTransactions: recent.cast(),
        todayExpense: summary['today_expense'] ?? 0,
      ));
    } catch (e) {
      emit(DashboardError('Gagal memuat dashboard: $e'));
    }
  }
}
