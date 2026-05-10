import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_tile.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<TransactionBloc>().state;
    if (state is! TransactionLoaded) {
      context.read<TransactionBloc>().add(const LoadTransactions());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Group transaksi by date.
  Map<DateTime, List<TransactionModel>> _groupByDate(
      List<TransactionModel> txs) {
    final map = <DateTime, List<TransactionModel>>{};
    for (final tx in txs) {
      final key = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchController.clear();
                  context.read<TransactionBloc>().add(const SearchTransactions(''));
                }
              });
            },
          ),
        ],
        bottom: _searchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => context
                        .read<TransactionBloc>()
                        .add(SearchTransactions(v)),
                    decoration: InputDecoration(
                      hintText: 'Cari payee atau catatan...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionError) showErrorSnackbar(context, state.message);
        },
        builder: (context, state) {
          if (state is TransactionLoading || state is TransactionInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionLoaded) {
            if (state.transactions.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'Belum ada transaksi',
                subtitle: 'Mulai catat pengeluaran pertamamu hari ini.',
              );
            }
            final grouped = _groupByDate(state.transactions);
            final dates = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<TransactionBloc>().add(const LoadTransactions());
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _SummaryCard(
                      income: state.totalIncome,
                      expense: state.totalExpense,
                      net: state.netAmount,
                    ),
                  ),
                  for (final date in dates) ...[
                    SliverToBoxAdapter(
                      child: _DateHeader(date: date),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final tx = grouped[date]![i];
                          return TransactionTile(
                            transaction: tx,
                            onDelete: () {
                              context
                                  .read<TransactionBloc>()
                                  .add(DeleteTransaction(tx.id));
                            },
                          );
                        },
                        childCount: grouped[date]!.length,
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double net;

  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Pemasukan',
              amount: income,
              color: AppColors.income,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _SummaryItem(
              label: 'Pengeluaran',
              amount: expense,
              color: AppColors.expense,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _SummaryItem(
              label: 'Selisih',
              amount: net,
              color: net >= 0 ? AppColors.income : AppColors.expense,
              icon: Icons.swap_vert_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          formatCurrencyCompact(amount),
          style: AppTypography.amountSmall.copyWith(color: color, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        formatGroupHeader(date),
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
