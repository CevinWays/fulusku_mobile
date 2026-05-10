import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Tampilkan snackbar error dengan styling konsisten.
///
/// Pakai di catch block atau saat state X.error muncul:
/// ```
/// showErrorSnackbar(context, 'Gagal memuat data');
/// ```
void showErrorSnackbar(
  BuildContext context,
  String message, {
  VoidCallback? onRetry,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: AppColors.danger,
      duration: duration,
      action: onRetry != null
          ? SnackBarAction(
              label: 'COBA LAGI',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}

/// Snackbar sukses (hijau).
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: AppColors.secondary,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Snackbar info netral.
void showInfoSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      duration: const Duration(seconds: 3),
    ),
  );
}
