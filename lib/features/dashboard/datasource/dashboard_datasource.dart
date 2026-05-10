import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/transaction_model.dart';

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

  /// Hitung total amount per type untuk bulan ini.
  /// Return map: {'income': X, 'expense': Y, 'today_expense': Z}.
  Future<Map<String, double>> getMonthSummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {'income': 0, 'expense': 0, 'today_expense': 0};
    }

    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final endMonth = DateTime(now.year, now.month + 1, 1);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final response = await _client
        .from(SupabaseTables.transactions)
        .select('amount, type, transaction_date, accounts!transactions_account_id_fkey!inner(user_id)')
        .eq('accounts.user_id', userId)
        .gte('transaction_date', fmt(startMonth))
        .lt('transaction_date', fmt(endMonth));

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
}
