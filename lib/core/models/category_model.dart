import 'package:equatable/equatable.dart';

import '../constants/enums.dart';

/// Model kategori transaksi.
/// Mapping ke tabel `categories`. user_id NULL = default system-wide.
class CategoryModel extends Equatable {
  final int id;
  final String? userId; // null = default
  final String name;
  final CategoryType type;
  final String? icon;
  final String? color;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isDefault = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      type: CategoryType.fromString(json['type'] as String),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: (json['is_default'] as bool?) ?? false,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        'name': name,
        'type': type.toDbString,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'is_default': isDefault,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'name': name,
        'type': type.toDbString,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'is_default': false, // user-created kategori selalu false
        'sort_order': sortOrder,
      };

  bool get isCustom => userId != null;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        icon,
        color,
        isDefault,
        sortOrder,
        createdAt,
      ];
}
