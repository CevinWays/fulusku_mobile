import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/account_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../auth/widgets/auth_form_field.dart';
import '../cubit/account_cubit.dart';
import '../cubit/account_state.dart';

class AddAccountSheet extends StatefulWidget {
  /// Jika null = mode tambah; jika tidak null = mode edit.
  final AccountModel? existing;

  const AddAccountSheet({super.key, this.existing});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  late AccountType _type;
  String? _icon;
  String? _color;

  static const _presetColors = [
    '#6C63FF', '#00C896', '#FF6B6B', '#FFB347',
    '#3498DB', '#9B59B6', '#1ABC9C', '#E67E22',
  ];

  static const _presetIcons = [
    '💵', '🏦', '💳', '📱', '💰', '🪙', '🐷', '🏧',
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _balanceController = TextEditingController(
      text: ex != null ? ex.initialBalance.toStringAsFixed(0) : '',
    );
    _type = ex?.type ?? AccountType.cash;
    _icon = ex?.icon ?? _presetIcons.first;
    _color = ex?.color ?? _presetColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.selectionClick();
    final balance = parseCurrency(_balanceController.text) ?? 0;
    final cubit = context.read<AccountCubit>();
    if (_isEdit) {
      cubit.updateAccount(
        id: widget.existing!.id,
        name: _nameController.text.trim(),
        type: _type,
        initialBalance: balance,
        icon: _icon,
        color: _color,
      );
    } else {
      cubit.addAccount(
        name: _nameController.text.trim(),
        type: _type,
        initialBalance: balance,
        icon: _icon,
        color: _color,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state is AccountSaved) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          showSuccessSnackbar(
            context,
            _isEdit ? 'Akun diperbarui' : 'Akun ditambahkan',
          );
        }
        if (state is AccountError) {
          showErrorSnackbar(context, state.message);
        }
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
                  _isEdit ? 'Edit Akun' : 'Tambah Akun',
                  style: AppTypography.heading2,
                ),
                const SizedBox(height: 4),
                Text(
                  'Buat dompet/rekening untuk pencatatan transaksi.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 20),

                // Nama
                AuthFormField(
                  label: 'Nama Akun',
                  hint: 'Contoh: BCA, GoPay, Tunai',
                  icon: Icons.label_outline_rounded,
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => validateRequired(v, 'Nama akun'),
                ),
                const SizedBox(height: 16),

                // Tipe
                Text('Tipe Akun',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AccountType.values.map((t) {
                    final selected = _type == t;
                    return ChoiceChip(
                      label: Text(t.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _type = t),
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Saldo awal
                AuthFormField(
                  label: 'Saldo Awal (Rp)',
                  hint: '0',
                  icon: Icons.account_balance_wallet_rounded,
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  validator: validateAmount,
                ),
                const SizedBox(height: 16),

                // Icon picker
                Text('Pilih Icon',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _presetIcons.map((emoji) {
                    final selected = _icon == emoji;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = emoji),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.background,
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                            width: selected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Color picker
                Text('Warna',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _presetColors.map((hex) {
                    final c = AppColors.fromHex(hex);
                    final selected = _color == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _color = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 8)]
                              : [],
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Submit
                BlocBuilder<AccountCubit, AccountState>(
                  buildWhen: (p, c) => c is AccountSaving || p is AccountSaving,
                  builder: (_, state) => AuthPrimaryButton(
                    label: _isEdit ? 'Simpan Perubahan' : 'Tambah Akun',
                    isLoading: state is AccountSaving,
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
}

/// Helper untuk show sheet (gunakan dari screen lain).
Future<void> showAddAccountSheet(
  BuildContext context, {
  AccountModel? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<AccountCubit>(),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddAccountSheet(existing: existing),
      ),
    ),
  );
}
