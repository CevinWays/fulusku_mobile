import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../budgets/cubit/budget_state.dart';
import '../../reports/cubit/report_state.dart';
import '../cubit/dashboard_state.dart';

class DashboardDatasource {
  final SupabaseClient _client;
  DashboardDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const _txSelect = '''
*,
categories ( id, name, type, icon, color, is_default, sort_order, user_id, created_at ),
accounts!transactions_account_id_fkey ( id, user_id, name, type, initial_balance, currency_code, icon, color, is_active, created_at, updated_at )
''';

  Future<List<AccountModel>> getAccounts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _client
        .from(SupabaseTables.accountBalances)
        .select()
        .eq('user_id', userId);
    return (response as List)
        .map((row) => AccountModel.fromBalanceView(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) async {
    final response = await _client
        .from(SupabaseTables.transactions)
        .select(_txSelect)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((r) => TransactionModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Hitung total amount per type untuk satu bulan.
  /// Default: bulan saat ini.
  /// Return map: {'income': X, 'expense': Y, 'today_expense': Z}.
  Future<Map<String, double>> getMonthSummary({DateTime? month}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {'income': 0, 'expense': 0, 'today_expense': 0};
    }

    final ref = month ?? DateTime.now();
    final startMonth = DateTime(ref.year, ref.month, 1);
    final endMonth = DateTime(ref.year, ref.month + 1, 1);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final tomorrow = today.add(const Duration(days: 1));

    final response = await _client
        .from(SupabaseTables.transactions)
        .select(
            'amount, type, transaction_date, accounts!transactions_account_id_fkey!inner(user_id)')
        .eq('accounts.user_id', userId)
        .gte('transaction_date', _fmt(startMonth))
        .lt('transaction_date', _fmt(endMonth));

    double income = 0, expense = 0, todayExpense = 0;
    for (final row in (response as List)) {
      final r = row as Map<String, dynamic>;
      final amount = (r['amount'] as num).toDouble();
      final type = r['type'] as String;
      final dateStr = r['transaction_date'] as String;
      final date = DateTime.parse(dateStr);

      if (type == 'income') income += amount;
      if (type == 'expense') {
        expense += amount;
        if (!date.isBefore(today) && date.isBefore(tomorrow)) {
          todayExpense += amount;
        }
      }
    }

    return {'income': income, 'expense': expense, 'today_expense': todayExpense};
  }

  /// Breakdown pengeluaran per kategori untuk bulan tertentu.
  /// Default: bulan saat ini. Diurutkan descending by amount.
  Future<List<CategorySpend>> getMonthlyCategoryBreakdown({
    DateTime? month,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final ref = month ?? DateTime.now();
    final summary = await _client
        .from(SupabaseTables.monthlyCategorySummary)
        .select()
        .eq('user_id', userId)
        .eq('year', ref.year)
        .eq('month', ref.month)
        .eq('trans_type', 'expense');

    final list = (summary as List).map((row) {
      final r = row as Map<String, dynamic>;
      return CategorySpend(
        CategoryModel(
          id: r['category_id'] as int,
          name: r['category_name'] as String,
          type: CategoryType.expense,
          icon: r['icon'] as String?,
          color: r['color'] as String?,
          createdAt: DateTime.now(),
        ),
        (r['total_amount'] as num).toDouble(),
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return list;
  }

  /// Total pengeluaran & pemasukan harian dari [start] (inclusive) sampai
  /// [end] (exclusive). Hari yang tidak punya transaksi tidak dimasukkan —
  /// caller bertanggung jawab mengisi gap kalau perlu.
  Future<List<DailyTotal>> getDailyTotals({
    required DateTime start,
    required DateTime end,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseTables.transactions)
        .select(
            'amount, type, transaction_date, accounts!transactions_account_id_fkey!inner(user_id)')
        .eq('accounts.user_id', userId)
        .gte('transaction_date', _fmt(start))
        .lt('transaction_date', _fmt(end));

    final dailyMap = <String, DailyTotal>{};
    for (final row in (response as List)) {
      final r = row as Map<String, dynamic>;
      final dateStr = r['transaction_date'] as String;
      final amount = (r['amount'] as num).toDouble();
      final type = r['type'] as String;
      final existing = dailyMap[dateStr];
      final exp = type == 'expense' ? amount : 0.0;
      final inc = type == 'income' ? amount : 0.0;
      dailyMap[dateStr] = DailyTotal(
        date: DateTime.parse(dateStr),
        expense: (existing?.expense ?? 0) + exp,
        income: (existing?.income ?? 0) + inc,
      );
    }

    return dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 7 hari terakhir termasuk hari ini, satu entry per hari (nol untuk hari
  /// tanpa transaksi). Cocok untuk sparkline di dashboard.
  Future<List<DailyTotal>> getLastWeekTrend() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final end = today.add(const Duration(days: 1));

    final fetched = await getDailyTotals(start: start, end: end);
    final byDate = {
      for (final d in fetched) _fmt(d.date): d,
    };

    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      return byDate[_fmt(day)] ??
          DailyTotal(date: day, expense: 0, income: 0);
    });
  }

  /// Ringkasan bulan lalu untuk perbandingan.
  Future<MonthSummary> getLastMonthSummary() async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final m = await getMonthSummary(month: lastMonth);
    return MonthSummary(
      income: m['income'] ?? 0,
      expense: m['expense'] ?? 0,
    );
  }

  /// Top-N budget berdasarkan persentase penggunaan (over-budget dulu).
  /// Mengembalikan list kosong jika user belum punya budget bulan ini.
  Future<List<BudgetWithProgress>> getTopBudgetProgress({int limit = 3}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final now = DateTime.now();
    final budgetData = await _client
        .from(SupabaseTables.budgets)
        .select('*, categories(*)')
        .eq('user_id', userId)
        .eq('month', now.month)
        .eq('year', now.year);

    if ((budgetData as List).isEmpty) return [];

    final spentData = await _client
        .from(SupabaseTables.monthlyCategorySummary)
        .select('category_id, total_amount')
        .eq('user_id', userId)
        .eq('year', now.year)
        .eq('month', now.month)
        .eq('trans_type', 'expense');

    final spentMap = <int, double>{};
    for (final row in (spentData as List)) {
      spentMap[row['category_id'] as int] =
          (row['total_amount'] as num).toDouble();
    }

    final all = budgetData.map((row) {
      final r = row;
      final cat =
          CategoryModel.fromJson(r['categories'] as Map<String, dynamic>);
      return BudgetWithProgress(
        id: r['id'] as int,
        category: cat,
        amountLimit: (r['amount_limit'] as num).toDouble(),
        spent: spentMap[cat.id] ?? 0,
        month: now.month,
        year: now.year,
      );
    }).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    return all.take(limit).toList();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
