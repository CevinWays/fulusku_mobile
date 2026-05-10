import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../transactions/widgets/transaction_tile.dart';
import '../cubit/report_cubit.dart';
import '../cubit/report_state.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/trend_line_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ReportCubit>().loadDailyReport();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      final cubit = context.read<ReportCubit>();
      final now = DateTime.now();
      switch (_tabController.index) {
        case 0:
          cubit.loadDailyReport();
          break;
        case 1:
          cubit.loadMonthlyReport(now.year, now.month);
          break;
        case 2:
          // Yearly stub — just leave state.
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Harian'),
            Tab(text: 'Bulanan'),
            Tab(text: 'Tahunan'),
          ],
        ),
      ),
      body: BlocConsumer<ReportCubit, ReportState>(
        listener: (context, state) {
          if (state is ReportError) showErrorSnackbar(context, state.message);
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDaily(state),
              _buildMonthly(state),
              _buildYearlyStub(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDaily(ReportState state) {
    if (state is ReportLoading || state is ReportInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is! DailyReportLoaded) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ReportCubit>().loadDailyReport(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Available to spend
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available to Spend',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(state.availableToSpend),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatDate(state.date),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Pemasukan Hari Ini',
                  amount: state.todayIncome,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniCard(
                  label: 'Pengeluaran Hari Ini',
                  amount: state.todayExpense,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Transaksi Hari Ini', style: AppTypography.heading3),
          const SizedBox(height: 8),
          if (state.todayTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Belum ada transaksi hari ini.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...state.todayTransactions.map(
              (tx) => TransactionTile(transaction: tx),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthly(ReportState state) {
    if (state is ReportLoading || state is ReportInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is! MonthlyReportLoaded) {
      return Center(
        child: TextButton(
          onPressed: () {
            final now = DateTime.now();
            context.read<ReportCubit>().loadMonthlyReport(now.year, now.month);
          },
          child: const Text('Muat laporan bulanan'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<ReportCubit>().loadMonthlyReport(state.year, state.month),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header bulan
          Center(
            child: Text(
              formatMonth(state.year, state.month),
              style: AppTypography.heading2,
            ),
          ),
          const SizedBox(height: 16),

          // 4 stats
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Pemasukan',
                  amount: state.totalIncome,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniCard(
                  label: 'Pengeluaran',
                  amount: state.totalExpense,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Selisih', style: AppTypography.caption),
                    Text(
                      formatCurrency(state.net),
                      style: AppTypography.amountSmall.copyWith(
                        color: state.net >= 0
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                Column(
                  children: [
                    Text('Saving Rate', style: AppTypography.caption),
                    Text(
                      '${state.savingRate.toStringAsFixed(0)}%',
                      style: AppTypography.amountSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pie chart
          Text('Pengeluaran per Kategori', style: AppTypography.heading3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: CategoryPieChart(
              data: state.categoryBreakdown,
              total: state.totalExpense,
            ),
          ),
          const SizedBox(height: 20),

          // Daily trend
          Text('Tren Pengeluaran Harian', style: AppTypography.heading3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: TrendLineChart(data: state.dailyTrend),
          ),
          const SizedBox(height: 20),

          // Budget vs Actual
          if (state.budgetVsActual.isNotEmpty) ...[
            Text('Anggaran vs Realisasi', style: AppTypography.heading3),
            const SizedBox(height: 12),
            ...state.budgetVsActual.map(
              (b) => BudgetProgressTile(budget: b),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearlyStub() {
    return const EmptyState(
      icon: Icons.bar_chart_rounded,
      title: 'Laporan Tahunan',
      subtitle: 'Fitur ini akan tersedia di update berikutnya.',
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _MiniCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(
            formatCurrencyCompact(amount),
            style: AppTypography.amountSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
