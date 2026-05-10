import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/account_model.dart';

/// Reusable widget untuk pilih akun (horizontal scrolling chips).
/// Dipakai di Add Transaction Sheet untuk pilih source/destination account.
class AccountSelector extends StatelessWidget {
  final List<AccountModel> accounts;
  final int? selectedId;
  final ValueChanged<AccountModel> onSelected;
  final String? excludeAccountId; // untuk hide source di destination selector

  const AccountSelector({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    this.excludeAccountId,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = excludeAccountId == null
        ? accounts
        : accounts.where((a) => a.id.toString() != excludeAccountId).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Belum ada akun. Tambah dulu di menu Akun.',
          style: AppTypography.bodySmall,
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final account = filtered[i];
          final isSelected = account.id == selectedId;
          final color = AppColors.fromHex(account.color);
          return _Chip(
            account: account,
            color: color,
            selected: isSelected,
            onTap: () => onSelected(account),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final AccountModel account;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.account,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppColors.background,
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  account.icon ?? '💳',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.name,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    account.type.label,
                    style: AppTypography.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
