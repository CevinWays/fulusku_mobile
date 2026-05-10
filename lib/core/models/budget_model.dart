import 'package:equatable/equatable.dart';

import 'category_model.dart';

/// Model batas pengeluaran per kategori per bulan.
/// Mapping ke tabel `budgets`.
///
/// UNIQUE constraint: (user_id, category_id, month, year) — gunakan UPSERT
/// jika set budget untuk kategori+bulan yang sama.
class BudgetModel extends Equatable {
  final int id;
  final String userId;
  final int categoryId;
  final double amountLimit;
  final int month;
  final int year;
  final DateTime createdAt;

  /// Joined data (dari select dengan JOIN categories).
  final CategoryModel? category;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amountLimit,
    required this.month,
    required this.year,
    required this.createdAt,
    this.category,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    CategoryModel? category;
    if (json['categories'] != null) {
      category = CategoryModel.fromJson(json['categories'] as Map<String, dynamic>);
    }
    return BudgetModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as int,
      amountLimit: _toDouble(json['amount_limit']),
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'amount_limit': amountLimit,
        'month': month,
        'year': year,
      };

  /// Untuk UPSERT — tanpa id (auto-generated jika baru) & created_at.
  Map<String, dynamic> toUpsertJson() => {
        'user_id': userId,
        'category_id': categoryId,
        'amount_limit': amountLimit,
        'month': month,
        'year': year,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        amountLimit,
        month,
        year,
        createdAt,
      ];
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
