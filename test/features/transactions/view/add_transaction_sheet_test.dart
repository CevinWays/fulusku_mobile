import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fulusku/core/utils/date_formatter.dart';
import 'package:fulusku/features/accounts/cubit/account_cubit.dart';
import 'package:fulusku/features/accounts/cubit/account_state.dart';
import 'package:fulusku/features/categories/cubit/category_cubit.dart';
import 'package:fulusku/features/transactions/bloc/transaction_bloc.dart';
import 'package:fulusku/features/transactions/bloc/transaction_event.dart';
import 'package:fulusku/features/transactions/bloc/transaction_state.dart';
import 'package:fulusku/features/transactions/view/add_transaction_sheet.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockAccountCubit extends MockCubit<AccountState> implements AccountCubit {}

class MockCategoryCubit extends MockCubit<CategoryState>
    implements CategoryCubit {}

void main() {
  late MockTransactionBloc txBloc;
  late MockAccountCubit accountCubit;
  late MockCategoryCubit categoryCubit;

  setUp(() {
    txBloc = MockTransactionBloc();
    accountCubit = MockAccountCubit();
    categoryCubit = MockCategoryCubit();
    when(() => txBloc.state).thenReturn(const TransactionInitial());
    when(() => accountCubit.state).thenReturn(const AccountLoaded([]));
    when(() => accountCubit.loadAccounts()).thenAnswer((_) async {});
    when(() => categoryCubit.state).thenReturn(const CategoryLoaded([]));
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    double? initialAmount,
    DateTime? initialDate,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<TransactionBloc>.value(value: txBloc),
            BlocProvider<AccountCubit>.value(value: accountCubit),
            BlocProvider<CategoryCubit>.value(value: categoryCubit),
          ],
          child: AddTransactionSheet(
            initialAmount: initialAmount,
            initialDate: initialDate,
          ),
        ),
      ),
    ));
  }

  testWidgets('future receipt date falls back to today with a warning',
      (tester) async {
    await pumpSheet(
      tester,
      initialDate: DateTime.now().add(const Duration(days: 60)),
    );

    expect(find.text(formatDate(DateTime.now())), findsOneWidget);
    expect(find.text('Tanggal di struk tidak valid, cek lagi.'), findsOneWidget);
  });

  testWidgets('past receipt date is kept without warning', (tester) async {
    final past = DateTime.now().subtract(const Duration(days: 3));
    await pumpSheet(tester, initialDate: past);

    expect(find.text('Tanggal di struk tidak valid, cek lagi.'), findsNothing);
  });

  testWidgets('validation toast shows inside the sheet', (tester) async {
    await pumpSheet(tester, initialAmount: 1000);

    await tester.ensureVisible(find.text('Simpan Transaksi'));
    await tester.tap(find.text('Simpan Transaksi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(
      find.descendant(
        of: find.byType(AddTransactionSheet),
        matching: find.text('Pilih akun sumber.'),
      ),
      findsOneWidget,
    );
  });
}
