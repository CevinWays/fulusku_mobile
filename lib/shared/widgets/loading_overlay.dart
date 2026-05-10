import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Overlay loading semi-transparan dengan CircularProgressIndicator.
/// Pakai sebagai child di Stack atau standalone full-screen.
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool dimmed;

  const LoadingOverlay({super.key, this.message, this.dimmed = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: dimmed
          ? AppColors.textPrimary.withValues(alpha: 0.4)
          : Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fullscreen loading dengan background solid (untuk splash/blocking states).
class FullScreenLoader extends StatelessWidget {
  final String? message;
  const FullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
