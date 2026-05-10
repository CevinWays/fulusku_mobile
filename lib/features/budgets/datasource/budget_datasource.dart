import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/models/category_model.dart';
import '../cubit/budget_state.dart';

class BudgetDatasource {
  final SupabaseClient _client;
  BudgetDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<BudgetWithProgress>> getBudgets(int year, int month) async {
    final userId = _client.auth.currentUser!.id;

    // Budget records dengan kategori joined
    final budgetData = await _client
        .from(SupabaseTables.budgets)
        .select('*, categories(*)')
        .eq('user_id', userId)
        .eq('month', month)
        .eq('year', year);

    // Spent per kategori dari view
    final spentData = await _client
        .from(SupabaseTables.monthlyCategorySummary)
        .select('category_id, total_amount')
        .eq('user_id', userId)
        .eq('year', year)
        .eq('month', month)
        .eq('trans_type', 'expense');

    final spentMap = <int, double>{};
    for (final row in (spentData as List)) {
      spentMap[row['category_id'] as int] = (row['total_amount'] as num).toDouble();
    }

    return (budgetData as List).map((row) {
      final r = row as Map<String, dynamic>;
      final cat = CategoryModel.fromJson(r['categories'] as Map<String, dynamic>);
      return BudgetWithProgress(
        id: r['id'] as int,
        category: cat,
        amountLimit: (r['amount_limit'] as num).toDouble(),
        spent: spentMap[cat.id] ?? 0,
        month: month,
        year: year,
      );
    }).toList();
  }

  Future<void> upsertBudget({
    required int categoryId,
    required double amountLimit,
    required int month,
    required int year,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from(SupabaseTables.budgets).upsert(
      {
        'user_id': userId,
        'category_id': categoryId,
        'amount_limit': amountLimit,
        'month': month,
        'year': year,
      },
      onConflict: 'user_id,category_id,month,year',
    );
  }

  Future<void> deleteBudget(int id) async {
    await _client.from(SupabaseTables.budgets).delete().eq('id', id);
  }

  /// Kategori expense yang BELUM punya budget bulan ini.
  Future<List<CategoryModel>> getCategoriesWithoutBudget(int month, int year) async {
    final userId = _client.auth.currentUser!.id;
    final existing = await _client
        .from(SupabaseTables.budgets)
        .select('category_id')
        .eq('user_id', userId)
        .eq('month', month)
        .eq('year', year);
    final usedIds =
        (existing as List).map((b) => b['category_id'] as int).toSet();

    final allCats = await _client
        .from(SupabaseTables.categories)
        .select()
        .or('user_id.is.null,user_id.eq.$userId')
        .eq('type', 'expense')
        .order('sort_order');

    return (allCats as List)
        .map((r) => CategoryModel.fromJson(r as Map<String, dynamic>))
        .where((c) => !usedIds.contains(c.id))
        .toList();
  }
}
