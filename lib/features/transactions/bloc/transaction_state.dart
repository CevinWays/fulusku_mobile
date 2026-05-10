import 'package:equatable/equatable.dart';

import '../../../core/constants/enums.dart';
import '../../../core/models/transaction_model.dart';

sealed class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;

  const TransactionLoaded(this.transactions);

  double get totalIncome => transactions
      .where((t) => t.type == TransType.income)
      .fold<double>(0, (s, t) => s + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type == TransType.expense)
      .fold<double>(0, (s, t) => s + t.amount);

  double get netAmount => totalIncome - totalExpense;

  @override
  List<Object?> get props => [transactions];
}

class TransactionSubmitting extends TransactionState {
  const TransactionSubmitting();
}

class TransactionSubmitted extends TransactionState {
  const TransactionSubmitted();
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
  @override
  List<Object?> get props => [message];
}
