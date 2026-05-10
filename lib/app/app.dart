import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/accounts/cubit/account_cubit.dart';
import '../features/accounts/datasource/account_datasource.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/datasource/auth_datasource.dart';
import '../features/budgets/cubit/budget_cubit.dart';
import '../features/budgets/datasource/budget_datasource.dart';
import '../features/categories/cubit/category_cubit.dart';
import '../features/dashboard/cubit/dashboard_cubit.dart';
import '../features/dashboard/datasource/dashboard_datasource.dart';
import '../features/reports/cubit/report_cubit.dart';
import '../features/reports/datasource/report_datasource.dart';
import '../features/scanner/cubit/scanner_cubit.dart';
import '../features/scanner/datasource/scanner_datasource.dart';
import '../features/transactions/bloc/transaction_bloc.dart';
import '../features/transactions/datasource/transaction_datasource.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class FuluskuApp extends StatelessWidget {
  const FuluskuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(AuthDatasource())..checkSession(),
        ),
        BlocProvider<AccountCubit>(
          create: (_) => AccountCubit(AccountDatasource()),
        ),
        BlocProvider<CategoryCubit>(
          create: (_) => CategoryCubit()..loadCategories(),
        ),
        BlocProvider<TransactionBloc>(
          create: (_) => TransactionBloc(TransactionDatasource()),
        ),
        BlocProvider<DashboardCubit>(
          create: (_) => DashboardCubit(DashboardDatasource()),
        ),
        BlocProvider<ScannerCubit>(
          create: (_) => ScannerCubit(ScannerDatasource()),
        ),
        BlocProvider<ReportCubit>(
          create: (_) => ReportCubit(ReportDatasource()),
        ),
        BlocProvider<BudgetCubit>(
          create: (_) => BudgetCubit(BudgetDatasource()),
        ),
      ],
      child: MaterialApp.router(
        title: 'fulusku',
        theme: buildAppTheme(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
