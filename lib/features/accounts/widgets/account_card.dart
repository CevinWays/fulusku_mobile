import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/account_model.dart';
import '../../../core/utils/currency_formatter.dart';

/// Card display untuk satu akun. Tap untuk edit, swipe atau menu untuk delete.
class AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onDelete,
  });

  IconData get _typeIcon {
    switch (account.type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bankDebit:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.eWallet:
        return Icons.smartphone_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(account.color);
    final balance = account.currentBalance ?? account.initialBalance;
    final isNegative = balance < 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: account.icon != null && account.icon!.isNotEmpty
                    ? Text(account.icon!, style: const TextStyle(fontSize: 22))
                    : Icon(_typeIcon, color: color, size: 24),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(account.type.label, style: AppTypography.caption),
                  ],
                ),
              ),

              // Saldo
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(balance),
                    style: AppTypography.amountSmall.copyWith(
                      color: isNegative ? AppColors.danger : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Saldo', style: AppTypography.caption),
                ],
              ),

              if (onDelete != null) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'edit' && onTap != null) onTap!();
                    if (v == 'delete') onDelete!();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
