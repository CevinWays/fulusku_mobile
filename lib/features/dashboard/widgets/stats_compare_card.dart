import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../cubit/dashboard_state.dart';
import 'stats_card_shell.dart';

/// Page 3: bulan ini vs bulan lalu (pengeluaran & pemasukan).
class StatsCompareCard extends StatelessWidget {
  final MonthSummary current;
  final MonthSummary previous;

  const StatsCompareCard({
    super.key,
    required this.current,
    required this.previous,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = current.income > 0 ||
        current.expense > 0 ||
        previous.income > 0 ||
        previous.expense > 0;

    return StatsCardShell(
      title: 'Bulan ini vs bulan lalu',
      child: !hasAny
          ? const StatsEmptyState(
              'Belum cukup data untuk perbandingan bulan lalu.')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _CompareTile(
                  label: 'Pengeluaran',
                  amount: current.expense,
                  deltaPercent: _deltaPercent(current.expense, previous.expense),
                  // Expense turun = favorable
                  favorableWhenDown: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompareTile(
                  label: 'Pemasukan',
                  amount: current.income,
                  deltaPercent: _deltaPercent(current.income, previous.income),
                  favorableWhenDown: false,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: _NetDelta(
              currentNet: current.income - current.expense,
              previousNet: previous.income - previous.expense,
            ),
          ),
        ),
      ],
    );
  }

  /// Persentase perubahan dari [previous] ke [current]. Null bila tidak
  /// terukur (previous == 0).
  double? _deltaPercent(double current, double previous) {
    if (previous == 0) return null;
    return (current - previous) / previous * 100;
  }
}

class _CompareTile extends StatelessWidget {
  final String label;
  final double amount;
  final double? deltaPercent;
  final bool favorableWhenDown;

  const _CompareTile({
    required this.label,
    required this.amount,
    required this.deltaPercent,
    required this.favorableWhenDown,
  });

  @override
  Widget build(BuildContext context) {
    final delta = deltaPercent;
    final isDown = (delta ?? 0) < 0;
    final favorable = delta == null
        ? null
        : (favorableWhenDown ? isDown : !isDown);
    final pillColor = favorable == null
        ? AppColors.textMuted
        : (favorable ? AppColors.income : AppColors.expense);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(
            formatCurrencyCompact(amount),
            style: AppTypography.amountSmall.copyWith(fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delta == null
                      ? Icons.remove_rounded
                      : (isDown
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded),
                  size: 12,
                  color: pillColor,
                ),
                const SizedBox(width: 2),
                Text(
                  delta == null
                      ? 'Baru'
                      : '${delta.abs().toStringAsFixed(0)}%',
                  style: AppTypography.caption.copyWith(
                    color: pillColor,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetDelta extends StatelessWidget {
  final double currentNet;
  final double previousNet;

  const _NetDelta({required this.currentNet, required this.previousNet});

  @override
  Widget build(BuildContext context) {
    final diff = currentNet - previousNet;
    final sign = diff >= 0 ? '+' : '-';
    final color = diff >= 0 ? AppColors.income : AppColors.expense;
    return Text.rich(
      TextSpan(
        style: AppTypography.caption,
        children: [
          const TextSpan(text: 'Selisih bersih: '),
          TextSpan(
            text: '$sign${formatCurrencyCompact(diff.abs())}',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
