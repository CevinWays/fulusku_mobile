import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../transactions/view/add_transaction_sheet.dart';
import '../cubit/scanner_cubit.dart';
import '../cubit/scanner_state.dart';

/// HITL Review screen — user verifikasi hasil OCR sebelum simpan.
class ReviewScreen extends StatelessWidget {
  final String? imagePath;

  const ReviewScreen({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Struk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () {
            context.read<ScannerCubit>().reset();
            context.pop();
          },
        ),
      ),
      body: BlocBuilder<ScannerCubit, ScannerState>(
        builder: (context, state) {
          if (state is! ScannerReview) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = state.result;
          final confidence = result.confidenceScore ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: state.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      color: AppColors.background,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      color: AppColors.background,
                      child: const Icon(Icons.broken_image_rounded,
                          color: AppColors.textMuted, size: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confidence indicator
              if (confidence > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: confidence >= 0.8
                        ? AppColors.income.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        confidence >= 0.8
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: confidence >= 0.8
                            ? AppColors.income
                            : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          confidence >= 0.8
                              ? 'Hasil OCR akurat (${(confidence * 100).toStringAsFixed(0)}%). Periksa sekali lagi.'
                              : 'Akurasi rendah (${(confidence * 100).toStringAsFixed(0)}%). Periksa & koreksi.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Info cards
              if (result.merchantName != null)
                _InfoTile(
                  icon: Icons.store_rounded,
                  label: 'Nama Toko',
                  value: result.merchantName!,
                ),
              if (result.totalAmount != null)
                _InfoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Total',
                  value: formatCurrency(result.totalAmount!),
                  highlight: true,
                ),
              if (result.transactionDate != null)
                _InfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal',
                  value: formatDate(result.transactionDate!),
                ),
              if (result.taxAmount != null && result.taxAmount! > 0)
                _InfoTile(
                  icon: Icons.percent_rounded,
                  label: 'Pajak',
                  value: formatCurrency(result.taxAmount!),
                ),

              if (result.lineItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Detail Item', style: AppTypography.heading3),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: result.lineItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.description,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              formatCurrencyCompact(item.totalPrice),
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Empty state — OCR gagal
              if (result.merchantName == null && result.totalAmount == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'OCR tidak bisa baca struk. Kamu bisa input manual.',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<ScannerCubit>().reset();
                        context.pop();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Pindai Ulang'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<ScannerCubit>().reset();
                        // Pop ke halaman sebelumnya, lalu buka add transaction sheet
                        // dengan data OCR sebagai initial values.
                        context.pop();
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (context.mounted) {
                            showAddTransactionSheet(
                              context,
                              initialAmount: result.totalAmount,
                              initialPayee: result.merchantName,
                              initialDate: result.transactionDate,
                              receiptImageUrl: result.rawImageUrl,
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Lanjut Catat'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: highlight ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: highlight
                      ? AppTypography.amount.copyWith(
                          color: AppColors.primary,
                          fontSize: 18,
                        )
                      : AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
