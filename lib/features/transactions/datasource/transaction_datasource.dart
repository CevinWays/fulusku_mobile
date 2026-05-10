import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../../core/models/transaction_model.dart';

class TransactionDatasource {
  final SupabaseClient _client;
  TransactionDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const _selectWithRelations = '''
*,
categories ( id, name, type, icon, color, is_default, sort_order, user_id, created_at ),
accounts!transactions_account_id_fkey ( id, user_id, name, type, initial_balance, currency_code, icon, color, is_active, created_at, updated_at )
''';

  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    int? accountId,
    TransType? type,
    int limit = 100,
  }) async {
    var query = _client.from(SupabaseTables.transactions).select(_selectWithRelations);

    if (startDate != null) {
      query = query.gte('transaction_date', _fmtDate(startDate));
    }
    if (endDate != null) {
      query = query.lte('transaction_date', _fmtDate(endDate));
    }
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (accountId != null) query = query.eq('account_id', accountId);
    if (type != null) query = query.eq('type', type.toDbString);

    final response = await query
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => TransactionModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> addTransaction({
    required int accountId,
    int? destinationAccountId,
    required int categoryId,
    required double amount,
    required TransType type,
    required DateTime transactionDate,
    String? payee,
    String? notes,
    String? receiptImageUrl,
  }) async {
    final response = await _client
        .from(SupabaseTables.transactions)
        .insert({
          'account_id': accountId,
          'destination_account_id': ?destinationAccountId,
          'category_id': categoryId,
          'amount': amount,
          'type': type.toDbString,
          'transaction_date': _fmtDate(transactionDate),
          'payee': ?payee,
          'notes': ?notes,
          'receipt_image_url': ?receiptImageUrl,
        })
        .select(_selectWithRelations)
        .single();

    return TransactionModel.fromJson(response);
  }

  Future<void> deleteTransaction(int id) async {
    await _client.from(SupabaseTables.transactions).delete().eq('id', id);
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    final response = await _client
        .from(SupabaseTables.transactions)
        .select(_selectWithRelations)
        .or('payee.ilike.%$query%,notes.ilike.%$query%')
        .order('transaction_date', ascending: false)
        .limit(50);

    return (response as List)
        .map((row) => TransactionModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
