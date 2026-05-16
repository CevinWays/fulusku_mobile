# Transaction Detail Screen — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Buat halaman full-screen read-only untuk melihat detail satu transaksi, lengkap dengan hero section, detail rows, receipt thumbnail, dan tombol hapus.

**Architecture:** `TransactionDetailScreen` adalah `StatelessWidget` yang menerima `TransactionModel` via GoRouter `extra`. Tidak ada network call baru — data sudah tersedia dari list. Delete delegasi ke `TransactionBloc` yang sudah ada (optimistic pop).

**Tech Stack:** Flutter, `flutter_bloc`, `go_router`, `cached_network_image ^3.4.1`, `mocktail`, `bloc_test`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/features/transactions/view/transaction_detail_screen.dart` | **Create** | Detail screen + sub-widgets (Hero, DetailRow, ReceiptSection) |
| `lib/app/router.dart` | **Edit** | Tambah route `/transactions/:id` |
| `lib/features/transactions/view/transaction_list_screen.dart` | **Edit** | `onTap` tile → navigasi ke detail |
| `lib/features/dashboard/view/dashboard_screen.dart` | **Edit** | `onTap` recent tile → navigasi ke detail |
| `test/features/transactions/view/transaction_detail_screen_test.dart` | **Create** | 4 widget tests TDD |

---

### Task 1: Widget Tests (TDD — Red Phase)

**Files:**
- Create: `test/features/transactions/view/transaction_detail_screen_test.dart`

- [ ] **Step 1: Buat file test**

```dart
// test/features/transactions/view/transaction_detail_screen_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fulusku/core/constants/enums.dart';
import 'package:fulusku/core/models/category_model.dart';
import 'package:fulusku/core/models/transaction_model.dart';
import 'package:fulusku/features/transactions/bloc/transaction_bloc.dart';
import 'package:fulusku/features/transactions/bloc/transaction_event.dart';
import 'package:fulusku/features/transactions/bloc/transaction_state.dart';
import 'package:fulusku/features/transactions/view/transaction_detail_screen.dart';

class MockTransactionBloc
    extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

TransactionModel _buildTx({
  String? payee,
  String? notes,
  String? receiptImageUrl,
}) =>
    TransactionModel(
      id: 1,
      accountId: 1,
      categoryId: 1,
      amount: 271000,
      type: TransType.expense,
      transactionDate: DateTime(2026, 5, 16),
      createdAt: DateTime(2026, 5, 16, 17, 4),
      updatedAt: DateTime(2026, 5, 16, 17, 4),
      payee: payee,
      notes: notes,
      receiptImageUrl: receiptImageUrl,
      category: CategoryModel(
        id: 1,
        name: 'Makanan & Minuman',
        type: CategoryType.expense,
        icon: '🍔',
        color: '#E74C3C',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

void main() {
  late MockTransactionBloc bloc;

  setUp(() {
    bloc = MockTransactionBloc();
    when(() => bloc.state).thenReturn(const TransactionInitial());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() => reset(bloc));

  Widget buildSubject(TransactionModel tx) => MaterialApp(
        home: BlocProvider<TransactionBloc>.value(
          value: bloc,
          child: TransactionDetailScreen(transaction: tx),
        ),
      );

  group('TransactionDetailScreen', () {
    // TODO: implement TransactionDetailScreen in Task 2 to make these pass

    testWidgets('renders amount, category, and date', (tester) async {
      await tester.pumpWidget(buildSubject(_buildTx(payee: 'KFC Sudirman')));
      expect(find.textContaining('271.000'), findsOneWidget);
      expect(find.textContaining('Makanan'), findsWidgets);
      expect(find.textContaining('16 Mei 2026'), findsWidgets);
    });

    testWidgets('hides receipt section when receiptImageUrl is null',
        (tester) async {
      await tester.pumpWidget(buildSubject(_buildTx()));
      expect(find.text('Bukti Struk'), findsNothing);
    });

    testWidgets('shows receipt section when receiptImageUrl is set',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(_buildTx(receiptImageUrl: 'https://example.com/r.jpg')),
      );
      expect(find.text('Bukti Struk'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog on trash tap', (tester) async {
      await tester.pumpWidget(buildSubject(_buildTx()));
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Hapus Transaksi?'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Jalankan test — harus FAIL (TDD red)**

```bash
cd /home/cevinmabook/Developer/fulusku_mobile
flutter test test/features/transactions/view/transaction_detail_screen_test.dart --no-pub 2>&1 | tail -10
```

Expected: FAIL — `transaction_detail_screen.dart` belum ada.

- [ ] **Step 3: Commit test file**

```bash
git add test/features/transactions/view/transaction_detail_screen_test.dart
git commit -m "test: add widget tests for TransactionDetailScreen (TDD red)"
```

---

### Task 2: Implement `TransactionDetailScreen`

**Files:**
- Create: `lib/features/transactions/view/transaction_detail_screen.dart`

- [ ] **Step 1: Buat file screen**

```dart
// lib/features/transactions/view/transaction_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  Color _amountColor(TransType type) {
    switch (type) {
      case TransType.income:
        return AppColors.income;
      case TransType.expense:
        return AppColors.expense;
      case TransType.transfer:
        return AppColors.transfer;
    }
  }

  String _amountPrefix(TransType type) {
    switch (type) {
      case TransType.income:
        return '+';
      case TransType.expense:
        return '-';
      case TransType.transfer:
        return '';
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi?'),
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context); // optimistic: kembali ke list
      context.read<TransactionBloc>().add(DeleteTransaction(transaction.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final cat = tx.category;
    final color = AppColors.fromHex(cat?.color);
    final amountColor = _amountColor(tx.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.danger,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat?.icon ?? '📦',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_amountPrefix(tx.type)}${formatCurrency(tx.amount)}',
                    style: AppTypography.amountLarge.copyWith(color: amountColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(tx.transactionDate),
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      switch (tx.type) {
                        TransType.income => 'Pemasukan',
                        TransType.expense => 'Pengeluaran',
                        TransType.transfer => 'Transfer',
                      },
                      style: AppTypography.caption.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Detail rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Kategori',
                    value: cat != null
                        ? '${cat.icon ?? ''} ${cat.name}'.trim()
                        : '—',
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Toko / Penerima',
                    value: tx.payee?.isNotEmpty == true ? tx.payee! : '—',
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Akun',
                    value: tx.account?.name ?? '—',
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Catatan',
                    value: tx.notes?.isNotEmpty == true
                        ? tx.notes!
                        : 'Tidak ada catatan',
                    valueMuted: tx.notes?.isNotEmpty != true,
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Dicatat',
                    value:
                        '${formatDate(tx.createdAt)}, ${formatTime(tx.createdAt)}',
                    valueMuted: true,
                  ),
                ],
              ),
            ),

            // Receipt
            if (tx.receiptImageUrl != null) ...[
              const Divider(height: 1),
              _ReceiptSection(imageUrl: tx.receiptImageUrl!),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueMuted;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: valueMuted
                  ? AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic)
                  : AppTypography.body.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  final String imageUrl;

  const _ReceiptSection({required this.imageUrl});

  void _showFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bukti Struk', style: AppTypography.caption),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFullscreen(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 80,
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
dart analyze lib/features/transactions/view/transaction_detail_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Jalankan tests — harus PASS**

```bash
flutter test test/features/transactions/view/transaction_detail_screen_test.dart --no-pub 2>&1 | tail -10
```

Expected: `All tests passed!` (4/4)

- [ ] **Step 4: Commit**

```bash
git add lib/features/transactions/view/transaction_detail_screen.dart
git commit -m "feat: add TransactionDetailScreen (read-only, delete support)"
```

---

### Task 3: Wire Navigation

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `lib/features/transactions/view/transaction_list_screen.dart`
- Modify: `lib/features/dashboard/view/dashboard_screen.dart`

- [ ] **Step 1: Tambah import di `router.dart`**

Di bagian imports `lib/app/router.dart`, tambahkan:

```dart
import '../features/transactions/view/transaction_detail_screen.dart';
```

- [ ] **Step 2: Tambah route `/transactions/:id` di `router.dart`**

Di `router.dart`, setelah route `/transactions`:

```dart
GoRoute(
  path: '/transactions',
  parentNavigatorKey: _rootNavKey,
  builder: (context, state) => const TransactionListScreen(),
),
// TAMBAH INI:
GoRoute(
  path: '/transactions/:id',
  parentNavigatorKey: _rootNavKey,
  builder: (context, state) {
    final tx = state.extra as TransactionModel?;
    if (tx == null) return const TransactionListScreen();
    return TransactionDetailScreen(transaction: tx);
  },
),
```

- [ ] **Step 3: Tambah `onTap` di `TransactionListScreen`**

Di `lib/features/transactions/view/transaction_list_screen.dart`, temukan `TransactionTile` di dalam `SliverChildBuilderDelegate` dan tambahkan `onTap`:

```dart
// SEBELUM:
return TransactionTile(
  transaction: tx,
  onDelete: () {
    context
        .read<TransactionBloc>()
        .add(DeleteTransaction(tx.id));
  },
);

// SESUDAH:
return TransactionTile(
  transaction: tx,
  onTap: () => context.push('/transactions/${tx.id}', extra: tx),
  onDelete: () {
    context
        .read<TransactionBloc>()
        .add(DeleteTransaction(tx.id));
  },
);
```

Tambahkan import `go_router` di atas file jika belum ada:
```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 4: Tambah `onTap` di `DashboardScreen`**

Di `lib/features/dashboard/view/dashboard_screen.dart`, temukan `TransactionTile` di recent transactions section dan tambahkan `onTap`:

```dart
// SEBELUM:
(_, i) => TransactionTile(
  transaction: state.recentTransactions[i],
),

// SESUDAH:
(_, i) => TransactionTile(
  transaction: state.recentTransactions[i],
  onTap: () => context.push(
    '/transactions/${state.recentTransactions[i].id}',
    extra: state.recentTransactions[i],
  ),
),
```

Pastikan `go_router` sudah di-import di dashboard_screen.dart.

- [ ] **Step 5: Analyze semua file yang diubah**

```bash
dart analyze lib/app/router.dart lib/features/transactions/view/transaction_list_screen.dart lib/features/dashboard/view/dashboard_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/app/router.dart \
        lib/features/transactions/view/transaction_list_screen.dart \
        lib/features/dashboard/view/dashboard_screen.dart
git commit -m "feat: wire navigation to TransactionDetailScreen from list and dashboard"
```

---

### Task 4: Run Full Test Suite + Push

- [ ] **Step 1: Jalankan semua tests**

```bash
cd /home/cevinmabook/Developer/fulusku_mobile
flutter test --no-pub 2>&1 | tail -10
```

Expected: `All tests passed!`

- [ ] **Step 2: Push ke remote**

```bash
git push
```
