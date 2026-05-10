import 'package:flutter_bloc/flutter_bloc.dart';

import '../datasource/budget_datasource.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final BudgetDatasource _datasource;
  BudgetCubit(this._datasource) : super(const BudgetInitial());

  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  Future<void> loadBudgets({int? year, int? month}) async {
    _currentMonth = month ?? _currentMonth;
    _currentYear = year ?? _currentYear;
    emit(const BudgetLoading());
    try {
      final list = await _datasource.getBudgets(_currentYear, _currentMonth);
      emit(BudgetLoaded(
        budgets: list,
        month: _currentMonth,
        year: _currentYear,
      ));
    } catch (e) {
      emit(BudgetError('Gagal memuat budget: $e'));
    }
  }

  Future<void> setBudget({
    required int categoryId,
    required double amountLimit,
  }) async {
    emit(const BudgetSaving());
    try {
      await _datasource.upsertBudget(
        categoryId: categoryId,
        amountLimit: amountLimit,
        month: _currentMonth,
        year: _currentYear,
      );
      await loadBudgets();
    } catch (e) {
      emit(BudgetError('Gagal menyimpan budget: $e'));
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      await _datasource.deleteBudget(id);
      await loadBudgets();
    } catch (e) {
      emit(BudgetError('Gagal menghapus budget: $e'));
    }
  }
}
