import 'package:equatable/equatable.dart';

import '../constants/enums.dart';
import 'account_model.dart';
import 'category_model.dart';

/// Model transaksi keuangan.
/// Mapping ke tabel `transactions`. amount selalu positif (>0); arah
/// uang ditentukan oleh field [type].
///
/// Untuk transfer, [destinationAccountId] wajib diisi (selain dari [accountId]).
///
/// Field [account] dan [category] di-populate saat query JOIN dengan
/// `select('*, accounts(...), categories(*)')`.
class TransactionModel extends Equatable {
  final int id;
  final int accountId;
  final int? destinationAccountId;
  final int categoryId;
  final double amount;
  final TransType type;
  final DateTime transactionDate;
  final String? payee;
  final String? notes;
  final String? receiptImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (opsional, dari query JOIN)
  final AccountModel? account;
  final AccountModel? destinationAccount;
  final CategoryModel? category;

  const TransactionModel({
    required this.id,
    required this.accountId,
    this.destinationAccountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.transactionDate,
    this.payee,
    this.notes,
    this.receiptImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.account,
    this.destinationAccount,
    this.category,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Parse joined relations jika ada
    AccountModel? account;
    if (json['accounts'] != null) {
      account = AccountModel.fromJson(json['accounts'] as Map<String, dynamic>);
    }

    CategoryModel? category;
    if (json['categories'] != null) {
      category = CategoryModel.fromJson(json['categories'] as Map<String, dynamic>);
    }

    return TransactionModel(
      id: json['id'] as int,
      accountId: json['account_id'] as int,
      destinationAccountId: json['destination_account_id'] as int?,
      categoryId: json['category_id'] as int,
      amount: _toDouble(json['amount']),
      type: TransType.fromString(json['type'] as String),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      payee: json['payee'] as String?,
      notes: json['notes'] as String?,
      receiptImageUrl: json['receipt_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      account: account,
      category: category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        if (destinationAccountId != null) 'destination_account_id': destinationAccountId,
        'category_id': categoryId,
        'amount': amount,
        'type': type.toDbString,
        'transaction_date': _formatDate(transactionDate),
        if (payee != null) 'payee': payee,
        if (notes != null) 'notes': notes,
        if (receiptImageUrl != null) 'receipt_image_url': receiptImageUrl,
      };

  /// Untuk INSERT — tanpa id, created_at, updated_at, dan joined relations.
  Map<String, dynamic> toInsertJson() => {
        'account_id': accountId,
        if (destinationAccountId != null) 'destination_account_id': destinationAccountId,
        'category_id': categoryId,
        'amount': amount,
        'type': type.toDbString,
        'transaction_date': _formatDate(transactionDate),
        if (payee != null) 'payee': payee,
        if (notes != null) 'notes': notes,
        if (receiptImageUrl != null) 'receipt_image_url': receiptImageUrl,
      };

  /// Format YYYY-MM-DD untuk kolom DATE.
  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Sign untuk display amount: -1 untuk expense, +1 untuk income, 0 untuk transfer.
  int get sign {
    switch (type) {
      case TransType.expense:
        return -1;
      case TransType.income:
        return 1;
      case TransType.transfer:
        return 0;
    }
  }

  bool get isTransfer => type == TransType.transfer;

  @override
  List<Object?> get props => [
        id,
        accountId,
        destinationAccountId,
        categoryId,
        amount,
        type,
        transactionDate,
        payee,
        notes,
        receiptImageUrl,
        createdAt,
        updatedAt,
      ];
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
