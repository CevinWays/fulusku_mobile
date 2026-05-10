import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/enums.dart';
import '../datasource/account_datasource.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final AccountDatasource _datasource;

  AccountCubit(this._datasource) : super(const AccountInitial());

  Future<void> loadAccounts() async {
    emit(const AccountLoading());
    try {
      final accounts = await _datasource.getAccounts();
      emit(AccountLoaded(accounts));
    } catch (e) {
      emit(AccountError(_friendly(e)));
    }
  }

  Future<void> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    String? icon,
    String? color,
  }) async {
    emit(const AccountSaving());
    try {
      await _datasource.addAccount(
        name: name,
        type: type,
        initialBalance: initialBalance,
        icon: icon,
        color: color,
      );
      emit(const AccountSaved());
      await loadAccounts();
    } catch (e) {
      emit(AccountError(_friendly(e)));
    }
  }

  Future<void> updateAccount({
    required int id,
    required String name,
    required AccountType type,
    required double initialBalance,
    String? icon,
    String? color,
  }) async {
    emit(const AccountSaving());
    try {
      await _datasource.updateAccount(
        id: id,
        name: name,
        type: type,
        initialBalance: initialBalance,
        icon: icon,
        color: color,
      );
      emit(const AccountSaved());
      await loadAccounts();
    } catch (e) {
      emit(AccountError(_friendly(e)));
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await _datasource.deleteAccount(id);
      await loadAccounts();
    } catch (e) {
      emit(AccountError(_friendly(e)));
    }
  }

  String _friendly(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Tidak ada koneksi. Periksa internet kamu.';
    }
    if (msg.contains('foreign key') || msg.contains('referenced')) {
      return 'Akun tidak bisa dihapus karena masih dipakai di transaksi.';
    }
    return 'Gagal memproses: ${e.toString()}';
  }
}
