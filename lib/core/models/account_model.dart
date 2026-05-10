import 'package:equatable/equatable.dart';

import '../constants/enums.dart';

/// Model untuk dompet/rekening pengguna.
/// Mapping ke tabel `accounts` di Supabase.
///
/// Field [currentBalance] tidak ada di tabel `accounts` — diisi saat query
/// dari view `account_balances`. Default null jika hanya ambil dari accounts.
class AccountModel extends Equatable {
  final int id;
  final String userId;
  final String name;
  final AccountType type;
  final double initialBalance;
  final String currencyCode;
  final String? icon;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Saldo dinamis dari view `account_balances`. Null jika belum dihitung.
  final double? currentBalance;

  const AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.initialBalance,
    this.currencyCode = 'IDR',
    this.icon,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.currentBalance,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: AccountType.fromString(json['type'] as String),
      initialBalance: _toDouble(json['initial_balance']),
      currencyCode: (json['currency_code'] as String?) ?? 'IDR',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      currentBalance: json['current_balance'] != null
          ? _toDouble(json['current_balance'])
          : null,
    );
  }

  /// Untuk parsing dari view `account_balances` (struktur fields berbeda).
  factory AccountModel.fromBalanceView(Map<String, dynamic> json) {
    final now = DateTime.now();
    return AccountModel(
      id: json['account_id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: AccountType.fromString(json['type'] as String),
      initialBalance: _toDouble(json['initial_balance']),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: now,
      updatedAt: now,
      currentBalance: _toDouble(json['current_balance']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type.toDbString,
        'initial_balance': initialBalance,
        'currency_code': currencyCode,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'is_active': isActive,
      };

  /// Untuk INSERT — tanpa id, created_at, updated_at (auto-generated).
  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'name': name,
        'type': type.toDbString,
        'initial_balance': initialBalance,
        'currency_code': currencyCode,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'is_active': isActive,
      };

  AccountModel copyWith({
    String? name,
    AccountType? type,
    double? initialBalance,
    String? icon,
    String? color,
    bool? isActive,
    double? currentBalance,
  }) {
    return AccountModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currencyCode: currencyCode,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        initialBalance,
        currencyCode,
        icon,
        color,
        isActive,
        createdAt,
        updatedAt,
        currentBalance,
      ];
}

/// Helper: PostgreSQL DECIMAL bisa datang sebagai num atau String.
double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
