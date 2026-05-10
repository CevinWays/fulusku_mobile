import 'package:equatable/equatable.dart';

import '../../../core/constants/enums.dart';

sealed class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? categoryId;
  final int? accountId;
  final TransType? type;

  const LoadTransactions({
    this.startDate,
    this.endDate,
    this.categoryId,
    this.accountId,
    this.type,
  });

  @override
  List<Object?> get props => [startDate, endDate, categoryId, accountId, type];
}

class AddTransaction extends TransactionEvent {
  final int accountId;
  final int? destinationAccountId;
  final int categoryId;
  final double amount;
  final TransType type;
  final DateTime transactionDate;
  final String? payee;
  final String? notes;
  final String? receiptImageUrl;

  const AddTransaction({
    required this.accountId,
    this.destinationAccountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.transactionDate,
    this.payee,
    this.notes,
    this.receiptImageUrl,
  });

  @override
  List<Object?> get props => [
        accountId,
        destinationAccountId,
        categoryId,
        amount,
        type,
        transactionDate,
        payee,
        notes,
        receiptImageUrl,
      ];
}

class DeleteTransaction extends TransactionEvent {
  final int transactionId;
  const DeleteTransaction(this.transactionId);
  @override
  List<Object?> get props => [transactionId];
}

class SearchTransactions extends TransactionEvent {
  final String query;
  const SearchTransactions(this.query);
  @override
  List<Object?> get props => [query];
}
