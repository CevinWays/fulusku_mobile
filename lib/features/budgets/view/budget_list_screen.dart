import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../cubit/budget_cubit.dart';
import '../cubit/budget_state.dart';
import 'set_budget_sheet.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    context.read<BudgetCubit>().loadBudgets(year: _year, month: _month);
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
    context.read<BudgetCubit>().loadBudgets(year: _year, month: _month);
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
    context.read<BudgetCubit>().loadBudgets(year: _year, month: _month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Anggaran'),
      ),
      body: Column(
        children: [
          // Month navigator
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _prevMonth,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      formatMonth(_year, _month),
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: BlocConsumer<BudgetCubit, BudgetState>(
              listener: (context, state) {
                if (state is BudgetError) {
                  showErrorSnackbar(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is BudgetLoading || state is BudgetInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is BudgetLoaded) {
                  if (state.budgets.isEmpty) {
                    return EmptyState(
                      icon: Icons.savings_rounded,
                      title: 'Belum ada anggaran',
                      subtitle: 'Set budget pertamamu untuk\nmonitor pengeluaran lebih disiplin.',
                      action: ElevatedButton.icon(
                        onPressed: () => showSetBudgetSheet(
                          context,
                          month: _month,
                          year: _year,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Set Budget Pertama'),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        context.read<BudgetCubit>().loadBudgets(year: _year, month: _month),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        _SummaryCard(
                          totalLimit: state.totalLimit,
                          totalSpent: state.totalSpent,
                          totalRemaining: state.totalRemaining,
                        ),
                        const SizedBox(height: 16),
                        ...state.budgets.map((b) => _BudgetCard(
                              budget: b,
                              onEdit: () => showSetBudgetSheet(
                                context,
                                month: _month,
                                year: _year,
                                existing: b,
                              ),
                              onDelete: () => _confirmDelete(context, b.id, b.category.name),
                            )),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSetBudgetSheet(
          context,
          month: _month,
          year: _year,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Set Budget'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Budget?'),
        content: Text('Budget $name bulan ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BudgetCubit>().deleteBudget(id);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalLimit;
  final double totalSpent;
  final double totalRemaining;

  const _SummaryCard({
    required this.totalLimit,
    required this.totalSpent,
    required this.totalRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalLimit > 0 ? (totalSpent / totalLimit * 100).clamp(0, 100) : 0.0;

    return Container(
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
          const Text('Total Anggaran',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            formatCurrency(totalLimit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai: ${formatCurrencyCompact(totalSpent)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                'Sisa: ${formatCurrencyCompact(totalRemaining)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetWithProgress budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _color {
    if (budget.isOverBudget) return AppColors.danger;
    if (budget.percentage >= 90) return AppColors.warning;
    if (budget.isNearLimit) return AppColors.warning.withValues(alpha: 0.7);
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(budget.category.icon ?? '📦', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category.name,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${formatCurrencyCompact(budget.spent)} / ${formatCurrencyCompact(budget.amountLimit)}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${budget.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (budget.percentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(_color),
              minHeight: 8,
            ),
          ),
          if (budget.isOverBudget) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                const SizedBox(width: 4),
                Text(
                  'Melebihi ${formatCurrencyCompact(budget.spent - budget.amountLimit)}',
                  style: AppTypography.caption.copyWith(color: AppColors.danger),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
