import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../../core/models/account_model.dart';

class AccountDatasource {
  final SupabaseClient _client;

  AccountDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Ambil semua akun + saldo dinamis dari view `account_balances`.
  Future<List<AccountModel>> getAccounts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseTables.accountBalances)
        .select()
        .eq('user_id', userId)
        .order('account_id');

    return (response as List)
        .map((row) => AccountModel.fromBalanceView(row as Map<String, dynamic>))
        .toList();
  }

  Future<AccountModel> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    String? icon,
    String? color,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from(SupabaseTables.accounts)
        .insert({
          'user_id': userId,
          'name': name,
          'type': type.toDbString,
          'initial_balance': initialBalance,
          'currency_code': 'IDR',
          'icon': ?icon,
          'color': ?color,
        })
        .select()
        .single();

    return AccountModel.fromJson(response);
  }

  Future<AccountModel> updateAccount({
    required int id,
    required String name,
    required AccountType type,
    required double initialBalance,
    String? icon,
    String? color,
  }) async {
    final response = await _client
        .from(SupabaseTables.accounts)
        .update({
          'name': name,
          'type': type.toDbString,
          'initial_balance': initialBalance,
          'icon': ?icon,
          'color': ?color,
        })
        .eq('id', id)
        .select()
        .single();

    return AccountModel.fromJson(response);
  }

  Future<void> deleteAccount(int id) async {
    await _client.from(SupabaseTables.accounts).delete().eq('id', id);
  }
}
