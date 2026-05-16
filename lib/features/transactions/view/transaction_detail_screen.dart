// lib/features/transactions/view/transaction_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  Color _amountColor(TransType type) {
    switch (type) {
      case TransType.income:
        return AppColors.income;
      case TransType.expense:
        return AppColors.expense;
      case TransType.transfer:
        return AppColors.transfer;
    }
  }

  String _amountPrefix(TransType type) {
    switch (type) {
      case TransType.income:
        return '+';
      case TransType.expense:
        return '-';
      case TransType.transfer:
        return '';
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi?'),
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context); // optimistic: kembali ke list
      context.read<TransactionBloc>().add(DeleteTransaction(transaction.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final cat = tx.category;
    final color = AppColors.fromHex(cat?.color);
    final amountColor = _amountColor(tx.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.danger,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat?.icon ?? '📦',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_amountPrefix(tx.type)}${formatCurrency(tx.amount)}',
                    style: AppTypography.amountLarge.copyWith(color: amountColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(tx.transactionDate),
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      switch (tx.type) {
                        TransType.income => 'Pemasukan',
                        TransType.expense => 'Pengeluaran',
                        TransType.transfer => 'Transfer',
                      },
                      style: AppTypography.caption.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Detail rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Kategori',
                    value: cat != null
                        ? '${cat.icon ?? ''} ${cat.name}'.trim()
                        : '—',
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Toko / Penerima',
                    value: tx.payee?.isNotEmpty == true ? tx.payee! : '—',
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Akun',
                    value: tx.account?.name ?? '—',
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Catatan',
                    value: tx.notes?.isNotEmpty == true
                        ? tx.notes!
                        : 'Tidak ada catatan',
                    valueMuted: tx.notes?.isNotEmpty != true,
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Dicatat',
                    value:
                        '${formatDateShort(tx.createdAt)}, ${formatTime(tx.createdAt)}',
                    valueMuted: true,
                  ),
                ],
              ),
            ),

            // Receipt
            if (tx.receiptImageUrl != null) ...[
              const Divider(height: 1),
              _ReceiptSection(imageUrl: tx.receiptImageUrl!),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueMuted;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: valueMuted
                  ? AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic)
                  : AppTypography.body.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  final String imageUrl;

  const _ReceiptSection({required this.imageUrl});

  void _showFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bukti Struk', style: AppTypography.caption),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFullscreen(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 80,
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
