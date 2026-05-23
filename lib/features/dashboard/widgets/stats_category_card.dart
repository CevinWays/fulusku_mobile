import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../reports/cubit/report_state.dart';
import 'stats_card_shell.dart';

/// Page 1: pengeluaran per kategori bulan ini.
/// Donut + legenda 3 baris (top 3 kategori + "Lainnya" kalau ada sisa).
class StatsCategoryCard extends StatelessWidget {
  final List<CategorySpend> spends;

  const StatsCategoryCard({super.key, required this.spends});

  static const _fallbackPalette = [
    AppColors.expense,
    AppColors.transfer,
    AppColors.warning,
    AppColors.income,
    AppColors.primary,
    AppColors.textMuted,
  ];

  @override
  Widget build(BuildContext context) {
    return StatsCardShell(
      title: 'Pengeluaran per kategori',
      onTap: () => context.push('/reports'),
      child: spends.isEmpty
          ? const StatsEmptyState('Belum ada pengeluaran bulan ini.')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final total = spends.fold<double>(0, (s, x) => s + x.amount);
    final top = spends.take(3).toList();
    final otherAmount = spends.skip(3).fold<double>(0, (s, x) => s + x.amount);
    final hasOther = otherAmount > 0;

    final segments = <_Segment>[];
    for (var i = 0; i < top.length; i++) {
      segments.add(_Segment(
        color: _colorFor(top[i], i),
        value: top[i].amount,
      ));
    }
    if (hasOther) {
      segments.add(_Segment(color: AppColors.textMuted, value: otherAmount));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _DonutPainter(segments: segments, total: total),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatCurrencyCompact(total),
                    style: AppTypography.amountSmall.copyWith(fontSize: 13),
                  ),
                  Text('total', style: AppTypography.caption),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < top.length; i++)
                _LegendRow(
                  color: _colorFor(top[i], i),
                  label: top[i].category.name,
                  percent: total > 0 ? (top[i].amount / total * 100) : 0,
                ),
              if (hasOther)
                _LegendRow(
                  color: AppColors.textMuted,
                  label: 'Lainnya',
                  percent: total > 0 ? (otherAmount / total * 100) : 0,
                  muted: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _colorFor(CategorySpend s, int index) {
    final fromHex = AppColors.fromHex(s.category.color);
    if (fromHex != AppColors.textMuted) return fromHex;
    return _fallbackPalette[index % _fallbackPalette.length];
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;
  final bool muted;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.percent,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted
                  ? AppTypography.bodySmall
                  : AppTypography.body.copyWith(fontSize: 13),
            ),
          ),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: AppTypography.caption.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment {
  final Color color;
  final double value;
  const _Segment({required this.color, required this.value});
}

class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;
  final double total;

  _DonutPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    // Track ring
    final track = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    var start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.total != total;
}
