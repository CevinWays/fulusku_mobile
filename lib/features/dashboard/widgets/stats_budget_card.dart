import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../budgets/cubit/budget_state.dart';
import 'stats_card_shell.dart';

/// Page 4: top-N budget progress untuk bulan ini.
class StatsBudgetCard extends StatelessWidget {
  final List<BudgetWithProgress> budgets;

  const StatsBudgetCard({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    return StatsCardShell(
      title: 'Progres anggaran',
      onTap: () => context.push('/budgets'),
      child: budgets.isEmpty
          ? const StatsEmptyState(
              'Belum ada anggaran bulan ini.\nKetuk untuk menambah.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final b in budgets.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _BudgetRow(budget: b),
                  ),
              ],
            ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final BudgetWithProgress budget;

  const _BudgetRow({required this.budget});

  Color get _barColor {
    final p = budget.percentage;
    if (budget.isOverBudget) return AppColors.danger;
    if (p >= 80) return AppColors.warning;
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = (budget.percentage / 100).clamp(0.0, 1.0);
    final label = budget.category.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(fontSize: 13),
              ),
            ),
            Text(
              '${formatCurrencyCompact(budget.spent)} / '
              '${formatCurrencyCompact(budget.amountLimit)}',
              style: AppTypography.caption.copyWith(
                color: budget.isOverBudget
                    ? AppColors.danger
                    : AppColors.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 6,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(_barColor),
          ),
        ),
      ],
    );
  }
}
