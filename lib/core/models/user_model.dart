import 'package:equatable/equatable.dart';

/// Wrapper minimal untuk data user yang relevan di app layer.
/// Sumber utama: `Supabase.instance.client.auth.currentUser`.
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? name;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final metadata = (json['user_metadata'] ?? json['raw_user_meta_data']) as Map<String, dynamic>?;
    return UserModel(
      id: json['id'] as String,
      email: (json['email'] ?? '') as String,
      name: metadata?['name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (name != null) 'name': name,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, email, name, createdAt];
}
