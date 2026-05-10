import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  Color get _amountColor {
    switch (transaction.type) {
      case TransType.income:
        return AppColors.income;
      case TransType.expense:
        return AppColors.expense;
      case TransType.transfer:
        return AppColors.transfer;
    }
  }

  String get _amountPrefix {
    switch (transaction.type) {
      case TransType.income:
        return '+';
      case TransType.expense:
        return '-';
      case TransType.transfer:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = transaction.category;
    final color = AppColors.fromHex(cat?.color);
    final title = transaction.payee?.isNotEmpty == true
        ? transaction.payee!
        : (cat?.name ?? 'Transaksi');

    return Dismissible(
      key: ValueKey('tx-${transaction.id}'),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        color: AppColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Hapus Transaksi?'),
            content: Text(
              'Transaksi $title sebesar ${formatCurrency(transaction.amount)} akan dihapus.',
              style: AppTypography.bodySmall,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat?.icon ?? '📦',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildSubtitle(),
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_amountPrefix${formatCurrencyCompact(transaction.amount)}',
                style: AppTypography.amountSmall.copyWith(color: _amountColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (transaction.category != null) parts.add(transaction.category!.name);
    if (transaction.account != null) parts.add(transaction.account!.name);
    parts.add(formatRelativeDate(transaction.transactionDate));
    return parts.join(' · ');
  }
}
