import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/category_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../auth/widgets/auth_form_field.dart';
import '../cubit/budget_cubit.dart';
import '../cubit/budget_state.dart';
import '../datasource/budget_datasource.dart';

class SetBudgetSheet extends StatefulWidget {
  final int month;
  final int year;
  final BudgetWithProgress? existing;

  const SetBudgetSheet({
    super.key,
    required this.month,
    required this.year,
    this.existing,
  });

  @override
  State<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<SetBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  CategoryModel? _selected;
  List<CategoryModel> _availableCats = [];
  bool _loadingCats = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _selected = widget.existing!.category;
      _amountController.text = widget.existing!.amountLimit.toStringAsFixed(0);
    } else {
      _loadCats();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCats() async {
    setState(() => _loadingCats = true);
    try {
      final cats = await BudgetDatasource()
          .getCategoriesWithoutBudget(widget.month, widget.year);
      if (mounted) setState(() => _availableCats = cats);
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Gagal load kategori: $e');
    } finally {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    if (_selected == null) {
      showErrorSnackbar(context, 'Pilih kategori terlebih dahulu.');
      return;
    }
    HapticFeedback.selectionClick();
    final amount = parseCurrency(_amountController.text) ?? 0;
    context.read<BudgetCubit>().setBudget(
          categoryId: _selected!.id,
          amountLimit: amount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return BlocListener<BudgetCubit, BudgetState>(
      listener: (context, state) {
        if (state is BudgetLoaded && _isSubmittingDone(state)) {
          Navigator.pop(context);
          showSuccessSnackbar(context, _isEdit ? 'Budget diperbarui' : 'Budget ditambahkan');
        }
        if (state is BudgetError) showErrorSnackbar(context, state.message);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEdit ? 'Edit Budget' : 'Set Budget Baru',
                  style: AppTypography.heading2,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tetapkan batas pengeluaran per kategori per bulan.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 20),

                // Category selector
                Text(
                  'Kategori',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isEdit)
                  // Edit mode — kategori fixed
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(_selected?.icon ?? '📦', style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(_selected?.name ?? '', style: AppTypography.body),
                      ],
                    ),
                  )
                else if (_loadingCats)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_availableCats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Semua kategori sudah punya budget bulan ini.',
                      style: AppTypography.bodySmall,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCats.map((c) {
                      final selected = _selected?.id == c.id;
                      final color = AppColors.fromHex(c.color);
                      return ChoiceChip(
                        avatar: Text(c.icon ?? '📦', style: const TextStyle(fontSize: 14)),
                        label: Text(c.name),
                        selected: selected,
                        onSelected: (_) => setState(() => _selected = c),
                        selectedColor: color.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: selected ? color : AppColors.textPrimary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: selected ? color : AppColors.border),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                AuthFormField(
                  label: 'Batas Pengeluaran (Rp)',
                  hint: 'Contoh: 1000000',
                  icon: Icons.account_balance_wallet_rounded,
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: validateAmount,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                BlocBuilder<BudgetCubit, BudgetState>(
                  buildWhen: (p, c) => c is BudgetSaving || p is BudgetSaving,
                  builder: (_, state) => AuthPrimaryButton(
                    label: _isEdit ? 'Simpan Perubahan' : 'Tambah Budget',
                    isLoading: state is BudgetSaving,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _wasSubmitting = false;
  bool _isSubmittingDone(BudgetState state) {
    // Detect: BudgetSaving → BudgetLoaded transition.
    // Pakai field instance untuk track previous saving state.
    if (state is BudgetSaving) {
      _wasSubmitting = true;
      return false;
    }
    if (state is BudgetLoaded && _wasSubmitting) {
      _wasSubmitting = false;
      return true;
    }
    return false;
  }
}

Future<void> showSetBudgetSheet(
  BuildContext context, {
  required int month,
  required int year,
  BudgetWithProgress? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<BudgetCubit>(),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SetBudgetSheet(month: month, year: year, existing: existing),
      ),
    ),
  );
}
