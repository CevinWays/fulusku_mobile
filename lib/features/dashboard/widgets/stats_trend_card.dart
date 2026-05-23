import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../reports/cubit/report_state.dart';
import 'stats_card_shell.dart';

/// Page 2: tren pengeluaran 7 hari terakhir sebagai sparkline.
class StatsTrendCard extends StatelessWidget {
  final List<DailyTotal> days;

  const StatsTrendCard({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final hasData = days.any((d) => d.expense > 0);
    return StatsCardShell(
      title: 'Tren 7 hari terakhir',
      child: !hasData
          ? const StatsEmptyState('Belum ada pengeluaran minggu ini.')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final total = days.fold<double>(0, (s, d) => s + d.expense);
    final fmt = DateFormat('d MMM', 'id_ID');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(formatCurrencyCompact(total),
                style: AppTypography.amountSmall.copyWith(fontSize: 18)),
            const SizedBox(width: 6),
            Text('total', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: CustomPaint(
            painter: _SparklinePainter(days: days),
            size: Size.infinite,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt.format(days.first.date), style: AppTypography.caption),
              Text(fmt.format(days.last.date), style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<DailyTotal> days;

  _SparklinePainter({required this.days});

  @override
  void paint(Canvas canvas, Size size) {
    if (days.length < 2) return;
    final maxVal =
        days.map((d) => d.expense).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    final dx = size.width / (days.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < days.length; i++) {
      final y = size.height - (days[i].expense / safeMax) * (size.height - 4);
      points.add(Offset(i * dx, y));
    }

    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.expense.withValues(alpha: 0.22),
          AppColors.expense.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.expense
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dot = Paint()..color = AppColors.expense;
    canvas.drawCircle(points.last, 3, dot);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.days != days;
}
