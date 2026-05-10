import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

/// Custom numpad untuk input nominal IDR.
/// Auto-format sambil ketik. Max 13 digit (sesuai DECIMAL(15,2)).
class AmountInputPad extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color? accentColor;

  const AmountInputPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  @override
  State<AmountInputPad> createState() => _AmountInputPadState();
}

class _AmountInputPadState extends State<AmountInputPad> {
  static const _maxDigits = 13;
  late String _digits;

  @override
  void initState() {
    super.initState();
    _digits = widget.value > 0 ? widget.value.toStringAsFixed(0) : '';
  }

  void _appendDigit(String d) {
    HapticFeedback.selectionClick();
    if (_digits.length >= _maxDigits) return;
    setState(() {
      if (_digits == '0') {
        _digits = d;
      } else {
        _digits = _digits + d;
      }
      _emit();
    });
  }

  void _appendThousand() {
    HapticFeedback.selectionClick();
    if (_digits.isEmpty) return;
    if (_digits.length + 3 > _maxDigits) return;
    setState(() {
      _digits = '${_digits}000';
      _emit();
    });
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    if (_digits.isEmpty) return;
    setState(() {
      _digits = _digits.substring(0, _digits.length - 1);
      _emit();
    });
  }

  void _emit() {
    final value = _digits.isEmpty ? 0.0 : double.parse(_digits);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? AppColors.primary;
    final value = _digits.isEmpty ? 0.0 : double.parse(_digits);

    return Column(
      children: [
        // Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              formatCurrency(value),
              key: ValueKey(_digits),
              style: AppTypography.amountLarge.copyWith(
                color: value > 0 ? color : AppColors.textMuted,
                fontSize: _digits.length > 9 ? 26 : 36,
              ),
            ),
          ),
        ),

        // Grid 4 baris
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 8),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 8),
        _buildRow(['000', '0', '⌫']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((k) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _NumpadButton(
              label: k,
              onTap: () {
                if (k == '⌫') {
                  _backspace();
                } else if (k == '000') {
                  _appendThousand();
                } else {
                  _appendDigit(k);
                }
              },
              isAction: k == '⌫' || k == '000',
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;

  const _NumpadButton({
    required this.label,
    required this.onTap,
    required this.isAction,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.isAction
                ? AppColors.background
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.label == '⌫' ? 22 : 22,
              fontWeight: FontWeight.w600,
              color: widget.isAction ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
