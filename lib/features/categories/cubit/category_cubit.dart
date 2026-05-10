import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../../core/models/category_model.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  const CategoryLoaded(this.categories);

  List<CategoryModel> ofType(CategoryType type) =>
      categories.where((c) => c.type == type).toList();

  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Cubit untuk load semua kategori (default + custom user).
/// Dipakai di Add Transaction Sheet, Reports, Budgets.
class CategoryCubit extends Cubit<CategoryState> {
  final SupabaseClient _client;

  CategoryCubit({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const CategoryInitial());

  Future<void> loadCategories() async {
    emit(const CategoryLoading());
    try {
      final response = await _client
          .from(SupabaseTables.categories)
          .select()
          .order('sort_order');
      final list = (response as List)
          .map((row) => CategoryModel.fromJson(row as Map<String, dynamic>))
          .toList();
      emit(CategoryLoaded(list));
    } catch (e) {
      emit(CategoryError('Gagal memuat kategori: $e'));
    }
  }
}
