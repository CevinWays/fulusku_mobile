import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../cubit/report_state.dart';

class BudgetProgressTile extends StatelessWidget {
  final BudgetProgress budget;

  const BudgetProgressTile({super.key, required this.budget});

  Color get _color {
    final pct = budget.percentage;
    if (pct >= 100) return AppColors.danger;
    if (pct >= 90) return AppColors.warning;
    if (pct >= 75) return AppColors.warning.withValues(alpha: 0.7);
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(budget.category.icon ?? '📦', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  budget.category.name,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${formatCurrencyCompact(budget.spent)} / ${formatCurrencyCompact(budget.budgetLimit)}',
                style: AppTypography.caption,
              ),
              if (budget.isOverBudget) ...[
                const SizedBox(width: 4),
                Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (budget.percentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(_color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
