import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fulusku/core/constants/enums.dart';
import 'package:fulusku/core/models/category_model.dart';
import 'package:fulusku/core/models/transaction_model.dart';
import 'package:fulusku/features/transactions/bloc/transaction_bloc.dart';
import 'package:fulusku/features/transactions/bloc/transaction_event.dart';
import 'package:fulusku/features/transactions/bloc/transaction_state.dart';
import 'package:fulusku/features/transactions/view/transaction_detail_screen.dart';

class MockTransactionBloc
    extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

TransactionModel _buildTx({
  TransType type = TransType.expense,
  String? payee,
  String? notes,
  String? receiptImageUrl,
}) =>
    TransactionModel(
      id: 1,
      accountId: 1,
      categoryId: 1,
      amount: 271000.0,
      type: type,
      transactionDate: DateTime(2026, 5, 16),
      createdAt: DateTime(2026, 5, 16, 17, 4),
      updatedAt: DateTime(2026, 5, 16, 17, 4),
      payee: payee,
      notes: notes,
      receiptImageUrl: receiptImageUrl,
      category: CategoryModel(
        id: 1,
        name: 'Makanan & Minuman',
        type: CategoryType.expense,
        icon: '🍔',
        color: '#E74C3C',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

void main() {
  late MockTransactionBloc bloc;

  setUp(() {
    bloc = MockTransactionBloc();
    when(() => bloc.state).thenReturn(const TransactionInitial());
  });

  tearDown(() => reset(bloc));

  Widget buildSubject(TransactionModel tx) => MaterialApp(
        home: BlocProvider<TransactionBloc>.value(
          value: bloc,
          child: TransactionDetailScreen(transaction: tx),
        ),
      );

  group('TransactionDetailScreen', () {
    // TODO: implement TransactionDetailScreen in Task 2 to make these pass

    testWidgets('renders formatted amount', (tester) async {
      await tester.pumpWidget(buildSubject(_buildTx()));
      expect(find.textContaining('271.000'), findsOneWidget);
    });

    testWidgets('renders category name', (tester) async {
      await tester.pumpWidget(buildSubject(_buildTx()));
      expect(find.textContaining('Makanan'), findsOneWidget);
    });

    testWidgets('renders transaction date', (tester) async {
      await tester.pumpWidget(buildSubject(_buildTx()));
      expect(find.textContaining('16 Mei 2026'), findsOneWidget);
    });

    testWidgets('hides receipt section when receiptImageUrl is null',
        (tester) async {
      await tester.pumpWidget(buildSubject(_buildTx()));
      expect(find.text('Bukti Struk'), findsNothing);
    });

    testWidgets('shows receipt section when receiptImageUrl is set',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(_buildTx(receiptImageUrl: 'https://example.com/r.jpg')),
      );
      expect(find.text('Bukti Struk'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog on trash tap', (tester) async {
      await tester.pumpWidget(buildSubject(_buildTx()));
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Hapus Transaksi?'), findsOneWidget);
    });
  });
}
