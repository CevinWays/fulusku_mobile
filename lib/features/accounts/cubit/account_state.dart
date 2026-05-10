import 'package:equatable/equatable.dart';

import '../../../core/models/account_model.dart';

sealed class AccountState extends Equatable {
  const AccountState();
  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  final List<AccountModel> accounts;

  const AccountLoaded(this.accounts);

  double get totalBalance =>
      accounts.fold<double>(0, (sum, a) => sum + (a.currentBalance ?? a.initialBalance));

  @override
  List<Object?> get props => [accounts];
}

class AccountSaving extends AccountState {
  const AccountSaving();
}

class AccountSaved extends AccountState {
  const AccountSaved();
}

class AccountError extends AccountState {
  final String message;
  const AccountError(this.message);

  @override
  List<Object?> get props => [message];
}
