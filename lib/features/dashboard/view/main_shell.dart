import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../transactions/view/add_transaction_sheet.dart';

/// Main shell dengan 4 tab + FAB di tengah untuk Add Transaction.
///
/// Tab paths:
/// /home  /reports  [FAB]  /budgets  /settings
class MainShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const MainShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  int get _currentIndex {
    if (currentLocation.startsWith('/home')) return 0;
    if (currentLocation.startsWith('/reports')) return 1;
    if (currentLocation.startsWith('/budgets')) return 3;
    if (currentLocation.startsWith('/settings')) return 4;
    return 0;
  }

  void _showAddOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tambah Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AddOption(
                    icon: Icons.edit_rounded,
                    label: 'Input Manual',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showAddTransactionSheet(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddOption(
                    icon: Icons.document_scanner_rounded,
                    label: 'Pindai Struk',
                    color: AppColors.income,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/scanner');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/reports');
        break;
      case 3:
        context.go('/budgets');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              selected: _currentIndex == 0,
              onTap: () => _onTap(context, 0),
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Laporan',
              selected: _currentIndex == 1,
              onTap: () => _onTap(context, 1),
            ),
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.savings_rounded,
              label: 'Anggaran',
              selected: _currentIndex == 3,
              onTap: () => _onTap(context, 3),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Setelan',
              selected: _currentIndex == 4,
              onTap: () => _onTap(context, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder screens untuk tab yang belum diimplementasi (akan di-replace
/// di plan-plan berikutnya).
class PlaceholderTabScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        icon: icon,
        title: title,
        subtitle: message,
      ),
    );
  }
}
