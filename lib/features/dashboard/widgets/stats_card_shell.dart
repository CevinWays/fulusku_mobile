import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// Bingkai bersama untuk semua kartu di [StatsCarousel] — judul kecil + slot
/// konten. Kalau [onTap] di-set, seluruh kartu jadi tap target (untuk
/// deep-link ke /reports atau /budgets).
class StatsCardShell extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StatsCardShell({
    super.key,
    required this.title,
    required this.child,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.caption)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Placeholder satu baris untuk kartu yang tidak punya data.
class StatsEmptyState extends StatelessWidget {
  final String message;
  const StatsEmptyState(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall,
      ),
    );
  }
}
