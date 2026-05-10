import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

/// Row 3-card quick stats di bawah balance card.
class QuickStatsRow extends StatelessWidget {
  final double todayExpense;
  final double monthRemaining;
  final int activeAccounts;

  const QuickStatsRow({
    super.key,
    required this.todayExpense,
    required this.monthRemaining,
    required this.activeAccounts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.today_rounded,
              iconColor: AppColors.expense,
              label: 'Hari Ini',
              value: formatCurrencyCompact(todayExpense),
              caption: 'Pengeluaran',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.savings_rounded,
              iconColor: AppColors.income,
              label: 'Sisa Bulan',
              value: formatCurrencyCompact(monthRemaining),
              caption: 'Net flow',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.primary,
              label: 'Akun Aktif',
              value: '$activeAccounts',
              caption: 'Dompet',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
