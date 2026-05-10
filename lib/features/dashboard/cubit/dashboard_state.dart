import 'package:equatable/equatable.dart';

import '../../../core/models/account_model.dart';
import '../../../core/models/transaction_model.dart';

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

  const DashboardLoaded({
    required this.accounts,
    required this.totalBalance,
    required this.monthIncome,
    required this.monthExpense,
    required this.recentTransactions,
    required this.todayExpense,
  });

  double get availableToSpend => totalBalance;
  double get monthNet => monthIncome - monthExpense;

  @override
  List<Object?> get props => [
        accounts,
        totalBalance,
        monthIncome,
        monthExpense,
        recentTransactions,
        todayExpense,
      ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
