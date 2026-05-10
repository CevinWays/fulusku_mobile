import 'package:flutter_bloc/flutter_bloc.dart';

import '../datasource/report_datasource.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportDatasource _datasource;
  ReportCubit(this._datasource) : super(const ReportInitial());

  Future<void> loadDailyReport({DateTime? date}) async {
    emit(const ReportLoading());
    try {
      final result = await _datasource.getDailyReport(date ?? DateTime.now());
      emit(result);
    } catch (e) {
      emit(ReportError('Gagal memuat laporan harian: $e'));
    }
  }

  Future<void> loadMonthlyReport(int year, int month) async {
    emit(const ReportLoading());
    try {
      final result = await _datasource.getMonthlyReport(year, month);
      emit(result);
    } catch (e) {
      emit(ReportError('Gagal memuat laporan bulanan: $e'));
    }
  }
}
