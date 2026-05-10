import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/transaction_model.dart';
import '../datasource/transaction_datasource.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

/// Debounce event transformer manual (tanpa rxdart/stream_transform).
EventTransformer<E> _debounce<E>(Duration duration) {
  return (events, mapper) async* {
    Timer? timer;
    final controller = StreamController<E>();
    final sub = events.listen((event) {
      timer?.cancel();
      timer = Timer(duration, () => controller.add(event));
    }, onDone: () async {
      timer?.cancel();
      await controller.close();
    });
    try {
      await for (final event in controller.stream.asyncExpand((e) => mapper(e))) {
        yield event;
      }
    } finally {
      timer?.cancel();
      await sub.cancel();
    }
  };
}

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionDatasource _datasource;
  List<TransactionModel> _cache = [];

  TransactionBloc(this._datasource) : super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<DeleteTransaction>(_onDelete);
    on<SearchTransactions>(
      _onSearch,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
  }

  Future<void> _onLoad(LoadTransactions e, Emitter<TransactionState> emit) async {
    emit(const TransactionLoading());
    try {
      final list = await _datasource.getTransactions(
        startDate: e.startDate,
        endDate: e.endDate,
        categoryId: e.categoryId,
        accountId: e.accountId,
        type: e.type,
      );
      _cache = list;
      emit(TransactionLoaded(list));
    } catch (err) {
      emit(TransactionError('Gagal memuat transaksi: $err'));
    }
  }

  Future<void> _onAdd(AddTransaction e, Emitter<TransactionState> emit) async {
    emit(const TransactionSubmitting());
    try {
      await _datasource.addTransaction(
        accountId: e.accountId,
        destinationAccountId: e.destinationAccountId,
        categoryId: e.categoryId,
        amount: e.amount,
        type: e.type,
        transactionDate: e.transactionDate,
        payee: e.payee,
        notes: e.notes,
        receiptImageUrl: e.receiptImageUrl,
      );
      emit(const TransactionSubmitted());
      add(const LoadTransactions());
    } catch (err) {
      emit(TransactionError('Gagal menyimpan: $err'));
    }
  }

  Future<void> _onDelete(DeleteTransaction e, Emitter<TransactionState> emit) async {
    try {
      await _datasource.deleteTransaction(e.transactionId);
      _cache = _cache.where((t) => t.id != e.transactionId).toList();
      emit(TransactionLoaded(_cache));
    } catch (err) {
      emit(TransactionError('Gagal menghapus: $err'));
    }
  }

  Future<void> _onSearch(SearchTransactions e, Emitter<TransactionState> emit) async {
    if (e.query.isEmpty) {
      emit(TransactionLoaded(_cache));
      return;
    }
    emit(const TransactionLoading());
    try {
      final list = await _datasource.searchTransactions(e.query);
      emit(TransactionLoaded(list));
    } catch (err) {
      emit(TransactionError('Gagal mencari: $err'));
    }
  }
}
