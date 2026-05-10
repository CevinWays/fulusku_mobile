import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../transactions/bloc/transaction_bloc.dart';
import '../../transactions/bloc/transaction_event.dart';
import '../../transactions/widgets/transaction_tile.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_stats_row.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final emailPrefix = user?.email?.split('@').first ?? 'kamu';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<DashboardCubit, DashboardState>(
          listener: (context, state) {
            if (state is DashboardError) {
              showErrorSnackbar(context, state.message);
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                final dashboardCubit = context.read<DashboardCubit>();
                final txBloc = context.read<TransactionBloc>();
                await dashboardCubit.loadDashboard();
                txBloc.add(const LoadTransactions());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Greeting
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_greeting, style: AppTypography.bodySmall),
                                const SizedBox(height: 2),
                                Text(
                                  emailPrefix,
                                  style: AppTypography.heading2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton.outlined(
                            onPressed: () => context.push('/accounts'),
                            icon: const Icon(Icons.account_balance_wallet_rounded),
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state is DashboardLoading || state is DashboardInitial)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is DashboardLoaded) ...[
                    SliverToBoxAdapter(
                      child: BalanceCard(
                        totalBalance: state.totalBalance,
                        monthIncome: state.monthIncome,
                        monthExpense: state.monthExpense,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: QuickStatsRow(
                        todayExpense: state.todayExpense,
                        monthRemaining: state.monthNet,
                        activeAccounts: state.accounts.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              'Transaksi Terbaru',
                              style: AppTypography.heading3,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/transactions'),
                              child: const Text('Lihat semua →'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.recentTransactions.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'Belum ada transaksi.\nMulai catat dengan tombol +.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => TransactionTile(
                            transaction: state.recentTransactions[i],
                          ),
                          childCount: state.recentTransactions.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
