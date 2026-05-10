import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../accounts/cubit/account_cubit.dart';
import '../../accounts/cubit/account_state.dart';
import '../../accounts/widgets/account_selector.dart';
import '../../auth/widgets/auth_form_field.dart';
import '../../categories/cubit/category_cubit.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/amount_input_pad.dart';
import '../widgets/category_selector.dart';

class AddTransactionSheet extends StatefulWidget {
  /// Initial values dari OCR review (Plan 06).
  final double? initialAmount;
  final String? initialPayee;
  final DateTime? initialDate;
  final int? initialCategoryId;
  final String? receiptImageUrl;

  const AddTransactionSheet({
    super.key,
    this.initialAmount,
    this.initialPayee,
    this.initialDate,
    this.initialCategoryId,
    this.receiptImageUrl,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  TransType _type = TransType.expense;
  double _amount = 0;
  AccountModel? _account;
  AccountModel? _destinationAccount;
  CategoryModel? _category;
  late DateTime _date;
  bool _showDetails = false;
  final _payeeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount ?? 0;
    _date = widget.initialDate ?? DateTime.now();
    if (widget.initialPayee != null) _payeeController.text = widget.initialPayee!;

    // Load accounts & categories saat sheet dibuka.
    context.read<AccountCubit>().loadAccounts();
    final catState = context.read<CategoryCubit>().state;
    if (catState is! CategoryLoaded) {
      context.read<CategoryCubit>().loadCategories();
    }
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  CategoryType get _categoryFilter {
    switch (_type) {
      case TransType.expense:
        return CategoryType.expense;
      case TransType.income:
        return CategoryType.income;
      case TransType.transfer:
        return CategoryType.transfer;
    }
  }

  Color get _accentColor {
    switch (_type) {
      case TransType.expense:
        return AppColors.expense;
      case TransType.income:
        return AppColors.income;
      case TransType.transfer:
        return AppColors.transfer;
    }
  }

  bool get _isValid {
    if (_amount <= 0) return false;
    if (_account == null) return false;
    if (_category == null) return false;
    if (_type == TransType.transfer) {
      if (_destinationAccount == null) return false;
      if (_destinationAccount!.id == _account!.id) return false;
    }
    return true;
  }

  void _submit() {
    if (!_isValid) {
      HapticFeedback.lightImpact();
      showErrorSnackbar(context, _validationMessage());
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<TransactionBloc>().add(AddTransaction(
          accountId: _account!.id,
          destinationAccountId: _type == TransType.transfer
              ? _destinationAccount!.id
              : null,
          categoryId: _category!.id,
          amount: _amount,
          type: _type,
          transactionDate: _date,
          payee: _payeeController.text.trim().isEmpty
              ? null
              : _payeeController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          receiptImageUrl: widget.receiptImageUrl,
        ));
  }

  String _validationMessage() {
    if (_amount <= 0) return 'Masukkan nominal terlebih dahulu.';
    if (_account == null) return 'Pilih akun sumber.';
    if (_category == null) return 'Pilih kategori.';
    if (_type == TransType.transfer && _destinationAccount == null) {
      return 'Pilih akun tujuan.';
    }
    if (_type == TransType.transfer &&
        _destinationAccount?.id == _account?.id) {
      return 'Akun tujuan harus berbeda.';
    }
    return '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _switchType(TransType t) {
    HapticFeedback.selectionClick();
    setState(() {
      _type = t;
      _category = null;
      if (t != TransType.transfer) _destinationAccount = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionSubmitted) {
          Navigator.of(context).pop();
          showSuccessSnackbar(context, 'Transaksi disimpan');
        }
        if (state is TransactionError) {
          showErrorSnackbar(context, state.message);
        }
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Type segments
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: _buildTypeSegments(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    AmountInputPad(
                      value: _amount,
                      onChanged: (v) => setState(() => _amount = v),
                      accentColor: _accentColor,
                    ),
                    const SizedBox(height: 16),

                    // Akun sumber
                    _SectionLabel(
                      _type == TransType.transfer ? 'Akun Sumber' : 'Akun',
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<AccountCubit, AccountState>(
                      builder: (context, state) {
                        final accs = state is AccountLoaded ? state.accounts : <AccountModel>[];
                        return AccountSelector(
                          accounts: accs,
                          selectedId: _account?.id,
                          onSelected: (a) => setState(() => _account = a),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Akun tujuan (hanya untuk transfer)
                    if (_type == TransType.transfer) ...[
                      const _SectionLabel('Akun Tujuan'),
                      const SizedBox(height: 8),
                      BlocBuilder<AccountCubit, AccountState>(
                        builder: (context, state) {
                          final accs = state is AccountLoaded ? state.accounts : <AccountModel>[];
                          return AccountSelector(
                            accounts: accs,
                            selectedId: _destinationAccount?.id,
                            onSelected: (a) => setState(() => _destinationAccount = a),
                            excludeAccountId: _account?.id.toString(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Kategori
                    const _SectionLabel('Kategori'),
                    const SizedBox(height: 8),
                    CategorySelector(
                      filterType: _categoryFilter,
                      selectedId: _category?.id,
                      onSelected: (c) => setState(() => _category = c),
                    ),
                    const SizedBox(height: 16),

                    // Detail expandable
                    InkWell(
                      onTap: () => setState(() => _showDetails = !_showDetails),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _showDetails
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showDetails ? 'Sembunyikan detail' : 'Detail (opsional)',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: _showDetails
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Column(
                        children: [
                          // Date
                          InkWell(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 18, color: AppColors.textMuted),
                                  const SizedBox(width: 12),
                                  Text(
                                    formatDate(_date),
                                    style: AppTypography.body,
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          AuthFormField(
                            label: 'Penerima / Toko',
                            hint: 'Contoh: Alfamart',
                            icon: Icons.store_rounded,
                            controller: _payeeController,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),

                          AuthFormField(
                            label: 'Catatan',
                            hint: 'Tambah catatan...',
                            icon: Icons.notes_rounded,
                            controller: _notesController,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    BlocBuilder<TransactionBloc, TransactionState>(
                      buildWhen: (p, c) => c is TransactionSubmitting || p is TransactionSubmitting,
                      builder: (context, state) => SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: state is TransactionSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: state is TransactionSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Simpan Transaksi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegments() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: TransType.values.map((t) {
          final selected = _type == t;
          Color activeColor;
          switch (t) {
            case TransType.expense:
              activeColor = AppColors.expense;
              break;
            case TransType.income:
              activeColor = AppColors.income;
              break;
            case TransType.transfer:
              activeColor = AppColors.transfer;
              break;
          }
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchType(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 8)]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  t.label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Helper untuk show sheet.
Future<void> showAddTransactionSheet(
  BuildContext context, {
  double? initialAmount,
  String? initialPayee,
  DateTime? initialDate,
  int? initialCategoryId,
  String? receiptImageUrl,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<TransactionBloc>()),
        BlocProvider.value(value: context.read<AccountCubit>()),
        BlocProvider.value(value: context.read<CategoryCubit>()),
      ],
      child: AddTransactionSheet(
        initialAmount: initialAmount,
        initialPayee: initialPayee,
        initialDate: initialDate,
        initialCategoryId: initialCategoryId,
        receiptImageUrl: receiptImageUrl,
      ),
    ),
  );
}
