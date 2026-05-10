import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../cubit/account_cubit.dart';
import '../cubit/account_state.dart';
import '../widgets/account_card.dart';
import 'add_account_sheet.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AccountCubit>().loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet & Rekening'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: BlocConsumer<AccountCubit, AccountState>(
        listener: (context, state) {
          if (state is AccountError) showErrorSnackbar(context, state.message);
        },
        builder: (context, state) {
          if (state is AccountLoading || state is AccountInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AccountLoaded) {
            if (state.accounts.isEmpty) {
              return EmptyState(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Belum ada akun',
                subtitle: 'Tambah dompet/rekening pertamamu untuk\nmulai mencatat transaksi.',
                action: ElevatedButton.icon(
                  onPressed: () => showAddAccountSheet(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Akun'),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<AccountCubit>().loadAccounts(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _TotalBalanceHeader(total: state.totalBalance),
                  const SizedBox(height: 8),
                  ...state.accounts.map((acc) => AccountCard(
                        account: acc,
                        onTap: () => showAddAccountSheet(context, existing: acc),
                        onDelete: () => _confirmDelete(context, acc.id, acc.name),
                      )),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddAccountSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Akun?'),
        content: Text(
          '"$name" beserta semua transaksi yang terkait akan dihapus permanen.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AccountCubit>().deleteAccount(id);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _TotalBalanceHeader extends StatelessWidget {
  final double total;
  const _TotalBalanceHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saldo Semua Akun',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
