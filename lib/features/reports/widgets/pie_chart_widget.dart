import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../cubit/report_state.dart';

class CategoryPieChart extends StatelessWidget {
  final List<CategorySpend> data;
  final double total;

  const CategoryPieChart({super.key, required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Belum ada pengeluaran bulan ini.',
            style: AppTypography.bodySmall,
          ),
        ),
      );
    }

    final sorted = [...data]..sort((a, b) => b.amount.compareTo(a.amount));
    final top = sorted.take(6).toList();
    final restTotal = sorted.skip(6).fold<double>(0, (s, e) => s + e.amount);

    final sections = [
      ...top.map((e) {
        final color = AppColors.fromHex(e.category.color);
        final pct = total > 0 ? e.amount / total * 100 : 0;
        return PieChartSectionData(
          value: e.amount,
          color: color,
          title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
          radius: 70,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
      }),
      if (restTotal > 0)
        PieChartSectionData(
          value: restTotal,
          color: AppColors.textMuted,
          title: '${(restTotal / total * 100).toStringAsFixed(0)}%',
          radius: 70,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...top.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LegendItem(
                    color: AppColors.fromHex(e.category.color),
                    label: e.category.name,
                    amount: e.amount,
                    total: total,
                  ),
                )),
            if (restTotal > 0)
              _LegendItem(
                color: AppColors.textMuted,
                label: 'Lainnya',
                amount: restTotal,
                total: total,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;
  final double total;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total * 100 : 0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label · ${pct.toStringAsFixed(0)}%',
            style: AppTypography.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatCurrencyCompact(amount),
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
