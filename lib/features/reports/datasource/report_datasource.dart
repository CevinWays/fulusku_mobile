import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/transaction_model.dart';
import '../cubit/report_state.dart';

class ReportDatasource {
  final SupabaseClient _client;
  ReportDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const _txSelect = '''
*,
categories ( id, name, type, icon, color, is_default, sort_order, user_id, created_at ),
accounts!transactions_account_id_fkey ( id, user_id, name, type, initial_balance, currency_code, icon, color, is_active, created_at, updated_at )
''';

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<DailyReportLoaded> getDailyReport(DateTime date) async {
    final userId = _client.auth.currentUser!.id;
    final dateStr = _fmt(date);

    // Total balance dari view
    final balanceData = await _client
        .from(SupabaseTables.accountBalances)
        .select('current_balance')
        .eq('user_id', userId);

    final totalBalance = (balanceData as List).fold<double>(
      0,
      (sum, row) => sum + ((row['current_balance'] as num?)?.toDouble() ?? 0),
    );

    // Transaksi hari ini
    final txData = await _client
        .from(SupabaseTables.transactions)
        .select(_txSelect)
        .eq('transaction_date', dateStr)
        .order('created_at', ascending: false);

    final txs = (txData as List)
        .map((r) => TransactionModel.fromJson(r as Map<String, dynamic>))
        .toList();

    final income = txs
        .where((t) => t.type == TransType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.type == TransType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    return DailyReportLoaded(
      date: date,
      availableToSpend: totalBalance,
      todayIncome: income,
      todayExpense: expense,
      todayTransactions: txs,
    );
  }

  Future<MonthlyReportLoaded> getMonthlyReport(int year, int month) async {
    final userId = _client.auth.currentUser!.id;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    // Summary view
    final summary = await _client
        .from(SupabaseTables.monthlyCategorySummary)
        .select()
        .eq('user_id', userId)
        .eq('year', year)
        .eq('month', month);

    double totalIncome = 0, totalExpense = 0;
    final breakdown = <CategorySpend>[];

    for (final row in (summary as List)) {
      final r = row as Map<String, dynamic>;
      final amount = (r['total_amount'] as num).toDouble();
      final type = r['trans_type'] as String;
      if (type == 'income') totalIncome += amount;
      if (type == 'expense') {
        totalExpense += amount;
        breakdown.add(CategorySpend(
          CategoryModel(
            id: r['category_id'] as int,
            name: r['category_name'] as String,
            type: CategoryType.fromString(type),
            icon: r['icon'] as String?,
            color: r['color'] as String?,
            createdAt: DateTime.now(),
          ),
          amount,
        ));
      }
    }
    breakdown.sort((a, b) => b.amount.compareTo(a.amount));

    // Daily trend dari transaksi
    final dailyResp = await _client
        .from(SupabaseTables.transactions)
        .select('amount, type, transaction_date, accounts!transactions_account_id_fkey!inner(user_id)')
        .eq('accounts.user_id', userId)
        .gte('transaction_date', _fmt(start))
        .lt('transaction_date', _fmt(end));

    final dailyMap = <String, DailyTotal>{};
    for (final row in (dailyResp as List)) {
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
    final dailyTrend = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Budget vs actual
    final budgetData = await _client
        .from(SupabaseTables.budgets)
        .select('*, categories(*)')
        .eq('user_id', userId)
        .eq('month', month)
        .eq('year', year);

    final budgetMap = {for (final b in breakdown) b.category.id: b.amount};
    final budgetVsActual = (budgetData as List).map((row) {
      final r = row as Map<String, dynamic>;
      final cat = CategoryModel.fromJson(r['categories'] as Map<String, dynamic>);
      return BudgetProgress(
        category: cat,
        budgetLimit: (r['amount_limit'] as num).toDouble(),
        spent: budgetMap[cat.id] ?? 0,
      );
    }).toList();

    return MonthlyReportLoaded(
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      categoryBreakdown: breakdown,
      dailyTrend: dailyTrend,
      budgetVsActual: budgetVsActual,
    );
  }

}
