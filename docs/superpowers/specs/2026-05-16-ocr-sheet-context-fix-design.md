# OCR → Add Transaction Sheet: Stale Context Fix

**Date:** 2026-05-16  
**Status:** Approved

## Problem

After OCR scan flow (pindai struk → review), `showAddTransactionSheet` dipanggil
dari `context` ReviewScreen yang sedang di-dispose (pop animation ~300ms belum
selesai). Sheet terbuka tapi `MediaQuery`/`InheritedWidget` chain rusak saat
ReviewScreen selesai di-dispose. Akibatnya rebuild yang dipicu keyboard atau
`showDatePicker` menampilkan layar blank abu-abu.

## Root Cause

`review_screen.dart` memakai `Future.delayed(200ms)` + `context.mounted` check
untuk show sheet setelah `context.pop()`. Context ReviewScreen masih "mounted"
saat 200ms (animasi belum selesai ~300ms), tapi widget ancestor-nya sedang
di-unmount. Saat sheet di-rebuild, traversal `InheritedWidget` menemukan ancestor
yang sudah invalid.

## Solution: ScannerCubit `ScannerConfirmed` state

### Komponen yang berubah

| File | Perubahan |
|------|-----------|
| `scanner_state.dart` | Tambah `ScannerConfirmed(ReceiptResultModel result)` |
| `scanner_cubit.dart` | Tambah `void confirm(ReceiptResultModel result)` |
| `review_screen.dart` | Ganti delayed-showSheet dengan `cubit.confirm(result)` + `context.pop()` |
| `main_shell.dart` | Wrap Scaffold dengan `BlocListener<ScannerCubit>` yang memanggil `showAddTransactionSheet` dari context MainShell |

### Data flow

```
ReviewScreen (tap "Lanjut Catat")
  → ScannerCubit.confirm(result)     # emit ScannerConfirmed
  → context.pop()                    # kembali ke MainShell

MainShell BlocListener
  → detects ScannerConfirmed
  → ScannerCubit.reset()             # kembali ke ScannerIdle
  → showAddTransactionSheet(context, # context MainShell selalu valid
      initialAmount, initialPayee, initialDate, receiptImageUrl)
```

### Mengapa ini benar

- `MainShell` adalah ShellRoute yang selalu ada selama user logged in — contextnya tidak pernah di-pop.
- `ScannerCubit` sudah disediakan di app root (`FuluskuApp`), accessible dari MainShell tanpa perubahan provider.
- Tidak ada timing hack, tidak ada stale context.

## Files NOT changed

- `add_transaction_sheet.dart` — tidak perlu diubah
- `camera_screen.dart` — tidak perlu diubah
- `router.dart` — tidak perlu diubah
