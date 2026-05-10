import 'package:intl/intl.dart';

final _idrFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final _idrFormatDecimal = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 2,
);

/// Format angka ke IDR: `1500000` → `Rp 1.500.000`.
/// Set [withDecimal] true untuk tampil 2 digit desimal.
String formatCurrency(double amount, {bool withDecimal = false}) {
  if (withDecimal) return _idrFormatDecimal.format(amount);
  return _idrFormat.format(amount);
}

/// Format compact untuk display di card/chart kecil.
/// `1.500.000` → `Rp 1.5jt`, `87.500` → `Rp 88rb`.
String formatCurrencyCompact(double amount) {
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (abs >= 1000000000) {
    return '${sign}Rp ${(abs / 1000000000).toStringAsFixed(1)}M';
  }
  if (abs >= 1000000) {
    return '${sign}Rp ${(abs / 1000000).toStringAsFixed(1)}jt';
  }
  if (abs >= 1000) {
    return '${sign}Rp ${(abs / 1000).toStringAsFixed(0)}rb';
  }
  return '${sign}Rp ${abs.toStringAsFixed(0)}';
}

/// Parse dari teks IDR ke double.
/// `Rp 1.500.000` → `1500000.0`, `1.500` → `1500.0`.
double? parseCurrency(String input) {
  final cleaned = input
      .replaceAll(RegExp(r'[Rr][Pp]\s*'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
