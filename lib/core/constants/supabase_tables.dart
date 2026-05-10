/// Konstanta nama tabel Supabase. Dipakai di semua datasource.
abstract class SupabaseTables {
  static const categories = 'categories';
  static const accounts = 'accounts';
  static const transactions = 'transactions';
  static const budgets = 'budgets';
  static const receiptLineItems = 'receipt_line_items';
  static const monthlySnapshots = 'monthly_snapshots';

  // Views
  static const accountBalances = 'account_balances';
  static const monthlyCategorySummary = 'monthly_category_summary';
}

/// Konstanta nama Storage bucket.
abstract class SupabaseBuckets {
  static const receipts = 'receipts';
}

/// Konstanta nama Edge Functions.
abstract class SupabaseFunctions {
  static const processReceipt = 'process-receipt';
  static const generateMonthlySnapshot = 'generate-monthly-snapshot';
}
