/// Tipe akun dompet/rekening.
/// Mapping ke kolom `accounts.type` dengan enum PostgreSQL `account_type`.
enum AccountType {
  cash,
  bankDebit,
  creditCard,
  eWallet;

  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Tunai';
      case AccountType.bankDebit:
        return 'Bank Debit';
      case AccountType.creditCard:
        return 'Kartu Kredit';
      case AccountType.eWallet:
        return 'E-Wallet';
    }
  }

  /// Parse dari string DB (`cash`, `bank_debit`, `credit_card`, `e_wallet`).
  static AccountType fromString(String value) {
    switch (value) {
      case 'cash':
        return AccountType.cash;
      case 'bank_debit':
        return AccountType.bankDebit;
      case 'credit_card':
        return AccountType.creditCard;
      case 'e_wallet':
        return AccountType.eWallet;
      default:
        return AccountType.cash;
    }
  }

  /// Untuk insert/update ke database.
  String get toDbString {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bankDebit:
        return 'bank_debit';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.eWallet:
        return 'e_wallet';
    }
  }
}

/// Tipe transaksi.
enum TransType {
  expense,
  income,
  transfer;

  String get label {
    switch (this) {
      case TransType.expense:
        return 'Pengeluaran';
      case TransType.income:
        return 'Pemasukan';
      case TransType.transfer:
        return 'Transfer';
    }
  }

  static TransType fromString(String value) {
    switch (value) {
      case 'expense':
        return TransType.expense;
      case 'income':
        return TransType.income;
      case 'transfer':
        return TransType.transfer;
      default:
        return TransType.expense;
    }
  }

  String get toDbString {
    switch (this) {
      case TransType.expense:
        return 'expense';
      case TransType.income:
        return 'income';
      case TransType.transfer:
        return 'transfer';
    }
  }
}

/// Tipe kategori — sama nilainya dengan TransType, tapi enum terpisah
/// untuk type-safety di model `CategoryModel`.
enum CategoryType {
  expense,
  income,
  transfer;

  String get label {
    switch (this) {
      case CategoryType.expense:
        return 'Pengeluaran';
      case CategoryType.income:
        return 'Pemasukan';
      case CategoryType.transfer:
        return 'Transfer';
    }
  }

  static CategoryType fromString(String value) {
    switch (value) {
      case 'expense':
        return CategoryType.expense;
      case 'income':
        return CategoryType.income;
      case 'transfer':
        return CategoryType.transfer;
      default:
        return CategoryType.expense;
    }
  }

  String get toDbString {
    switch (this) {
      case CategoryType.expense:
        return 'expense';
      case CategoryType.income:
        return 'income';
      case CategoryType.transfer:
        return 'transfer';
    }
  }
}
