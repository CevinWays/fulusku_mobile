import 'package:intl/intl.dart';

/// Format tanggal lengkap: `09 Mei 2026`.
String formatDate(DateTime date) =>
    DateFormat('dd MMM yyyy', 'id_ID').format(date);

/// Format tanggal pendek: `09/05/2026`.
String formatDateShort(DateTime date) =>
    DateFormat('dd/MM/yyyy').format(date);

/// Format header bulan: `Mei 2026`.
String formatMonth(int year, int month) =>
    DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

/// Format jam: `14:32`.
String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

/// Format tanggal relatif: `Hari ini`, `Kemarin`, `3 hari lalu`, atau tanggal lengkap.
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  if (diff > 0 && diff < 7) return '$diff hari lalu';
  if (diff == -1) return 'Besok';
  return formatDate(date);
}

/// Format header grouping di list transaksi: `Hari ini`, `Kemarin`, atau tanggal lengkap.
String formatGroupHeader(DateTime date) => formatRelativeDate(date);

/// Hari pertama bulan tertentu.
DateTime startOfMonth(int year, int month) => DateTime(year, month, 1);

/// Hari terakhir bulan tertentu.
DateTime endOfMonth(int year, int month) =>
    DateTime(year, month + 1, 0); // day 0 of next month = last day of current
