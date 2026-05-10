import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Bottom navigation 5 tab dengan FAB di tengah.
///
/// Tab:
/// 0 — Dashboard
/// 1 — Reports
/// 2 — [FAB Add Transaction] (bukan tab biasa, di-handle terpisah)
/// 3 — Budgets
/// 4 — Settings
///
/// Implementasi penuh di Plan 05 (Dashboard) dengan ShellRoute.
/// Untuk sekarang ini reusable widget yang menerima [currentIndex] dan [onTap].
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddPressed;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Laporan',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 48), // Space untuk FAB
            _NavItem(
              icon: Icons.savings_rounded,
              label: 'Anggaran',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Pengaturan',
              selected: currentIndex == 4,
              onTap: () => onTap(4),
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
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
