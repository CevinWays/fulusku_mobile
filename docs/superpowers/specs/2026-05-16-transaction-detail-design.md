# Transaction Detail Screen — Design Spec

**Date:** 2026-05-16  
**Status:** Approved  
**Scope:** Read-only transaction detail screen (full screen, GoRouter navigation)

---

## Problem

Tidak ada halaman untuk melihat detail transaksi. User hanya bisa melihat info singkat di tile list (payee, kategori, amount). Field seperti catatan, akun, waktu pencatatan, dan bukti struk tidak bisa diakses.

---

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Full screen (bukan bottom sheet) | Lebih banyak ruang untuk receipt image dan semua field |
| 2 | Read-only (tidak ada edit) | Edit di-defer ke sprint berikutnya |
| 3 | Pass `TransactionModel` via GoRouter `extra` | Hindari network call tambahan; data sudah ada di list |
| 4 | Delete tersedia di detail screen | User convenience — tidak perlu kembali ke list untuk hapus |
| 5 | Receipt sebagai thumbnail + tap fullscreen | UX yang lebih baik untuk melihat struk |

---

## Architecture

### Route

Tambah route baru di `lib/app/router.dart`:

```dart
GoRoute(
  path: '/transactions/:id',
  parentNavigatorKey: _rootNavKey,
  builder: (context, state) {
    final tx = state.extra as TransactionModel?;
    if (tx == null) return const TransactionListScreen(); // guard: deep link
    return TransactionDetailScreen(transaction: tx);
  },
),
```

### Navigation Entry Points

- `TransactionListScreen` → tap `TransactionTile` → `context.push('/transactions/${tx.id}', extra: tx)`
- `Dashboard` recent transactions → tap tile → sama

### State Management

Tidak ada cubit/bloc baru. `TransactionDetailScreen` adalah `StatelessWidget`. Delete delegasi ke `TransactionBloc` yang sudah di-provide di root.

---

## Component: `TransactionDetailScreen`

**File:** `lib/features/transactions/view/transaction_detail_screen.dart`

### Layout

```
AppBar
  title: "Detail Transaksi"
  actions: [IconButton(Icons.delete_outline_rounded, color: danger)]

Scrollable body:
  ┌─ Hero Section ───────────────────────────────┐
  │  [Category Icon 48px rounded]                │
  │  -Rp 271.000  (amount, color by type)        │
  │  Jumat, 16 Mei 2026  (transaction_date)      │
  │  [Badge: Pengeluaran / Pemasukan / Transfer] │
  └──────────────────────────────────────────────┘

  Detail Rows (label kiri, value kanan):
    Kategori     → icon + name (atau "—" jika null)
    Toko/Penerima → payee (atau "—" jika null/empty)
    Akun         → account.name (atau "—")
    Catatan      → notes (atau "Tidak ada catatan" italic)
    Dicatat      → createdAt formatted (dd MMM yyyy, HH:mm)

  Receipt Section (hanya jika receiptImageUrl != null):
    Label: "Bukti Struk"
    CachedNetworkImage thumbnail (80px height, rounded)
    Tap → showDialog fullscreen dengan InteractiveViewer (pinch-zoom)
```

### Delete Flow

1. User tap icon trash
2. `AlertDialog` konfirmasi: "Hapus transaksi ini? Tindakan tidak dapat dibatalkan."
3. Konfirmasi → `context.read<TransactionBloc>().add(DeleteTransaction(tx.id))`
4. `BlocListener` menunggu `TransactionLoaded` state (list refresh setelah delete)
5. `context.pop()` kembali ke list

### Error Handling

| Scenario | Handling |
|----------|----------|
| Delete gagal | `showErrorSnackbar(context, message)` — tidak pop |
| `receiptImageUrl` ada tapi image load error | `errorWidget`: `Icon(Icons.broken_image_outlined)` |
| `extra` null (direct deep link ke `/transactions/:id`) | Redirect ke `/transactions` |

---

## Files Changed

| File | Action |
|------|--------|
| `lib/features/transactions/view/transaction_detail_screen.dart` | **Create** |
| `lib/app/router.dart` | **Edit** — tambah route `/transactions/:id` |
| `lib/features/transactions/view/transaction_list_screen.dart` | **Edit** — `onTap` di tile navigasi ke detail |
| `lib/features/dashboard/view/dashboard_screen.dart` | **Edit** — `onTap` di recent transaction tile navigasi ke detail |
| `test/features/transactions/view/transaction_detail_screen_test.dart` | **Create** |

---

## Tests

| # | Test | Description |
|---|------|-------------|
| 1 | `renders all fields from transaction model` | Verifikasi amount, payee, kategori, akun, tanggal tampil |
| 2 | `hides receipt section when receiptImageUrl is null` | Receipt section tidak tampil |
| 3 | `shows receipt section when receiptImageUrl is set` | Thumbnail + "Lihat Struk" tampil |
| 4 | `shows delete confirmation dialog on trash tap` | AlertDialog muncul |

---

## Out of Scope (defer)

- Edit transaksi dari detail screen
- Deep link `/transactions/:id` dengan fetch by ID
- Share/export detail transaksi
