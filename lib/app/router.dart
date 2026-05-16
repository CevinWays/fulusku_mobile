import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/accounts/view/account_list_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/register_screen.dart';
import '../features/budgets/view/budget_list_screen.dart';
import '../features/dashboard/view/dashboard_screen.dart';
import '../features/dashboard/view/main_shell.dart';
import '../features/reports/view/reports_screen.dart';
import '../features/scanner/view/camera_screen.dart';
import '../features/scanner/view/review_screen.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/transactions/view/transaction_list_screen.dart';
import '../features/transactions/view/transaction_detail_screen.dart';
import '../shared/widgets/loading_overlay.dart';
import '../core/models/transaction_model.dart';

final _shellNavKey = GlobalKey<NavigatorState>();
final _rootNavKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/',
  refreshListenable: _AuthRefreshNotifier(),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/register';
    final isSplash = loc == '/';

    if (!isLoggedIn && !isAuthRoute && !isSplash) return '/login';
    if (isLoggedIn && (isAuthRoute || isSplash)) return '/home';
    if (!isLoggedIn && isSplash) return '/login';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FullScreenLoader(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Shell route untuk semua tab utama
    ShellRoute(
      navigatorKey: _shellNavKey,
      builder: (context, state, child) => MainShell(
        currentLocation: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/budgets',
          builder: (context, state) => const BudgetListScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),

    // Top-level routes (di luar shell)
    GoRoute(
      path: '/accounts',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const AccountListScreen(),
    ),
    GoRoute(
      path: '/transactions',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const TransactionListScreen(),
    ),
    GoRoute(
      path: '/transactions/:id',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) {
        final tx = state.extra as TransactionModel?;
        if (tx == null) return const TransactionListScreen();
        return TransactionDetailScreen(transaction: tx);
      },
    ),
    GoRoute(
      path: '/scanner',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/scanner/review',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ReviewScreen(
          imagePath: extra?['imagePath'] as String?,
        );
      },
    ),
  ],
);

class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthRefreshNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
