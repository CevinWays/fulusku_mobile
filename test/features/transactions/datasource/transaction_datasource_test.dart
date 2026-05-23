import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fulusku/features/transactions/datasource/transaction_datasource.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('TransactionDatasource.getReceiptSignedUrl passthrough', () {
    late TransactionDatasource ds;
    late _MockSupabaseClient client;

    setUp(() {
      client = _MockSupabaseClient();
      ds = TransactionDatasource(client: client);
    });

    test('returns full https URL unchanged without touching storage', () async {
      final result =
          await ds.getReceiptSignedUrl('https://example.com/receipt.jpg');
      expect(result, 'https://example.com/receipt.jpg');
      verifyNever(() => client.storage);
    });

    test('returns http URL unchanged without touching storage', () async {
      final result = await ds.getReceiptSignedUrl('http://legacy.example/x.jpg');
      expect(result, 'http://legacy.example/x.jpg');
      verifyNever(() => client.storage);
    });
  });
}
