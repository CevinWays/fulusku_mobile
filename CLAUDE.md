# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fulusku is a personal finance Flutter app with OCR receipt scanning, targeting the Indonesian market. UI language and error messages are in Indonesian.

`main.dart` locks orientation to portrait and initializes `intl` locale data for `id_ID` (used by `DateFormat`/`NumberFormat` formatters in `lib/core/utils/`).

## Commands

This project uses FVM (Flutter Version Manager) pinned to `stable` (see `.fvmrc`). Prefix all Flutter commands with `fvm`:

```bash
fvm flutter run                        # run on connected device/emulator
fvm flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...  # override Supabase credentials
fvm flutter test                       # run all tests
fvm flutter test test/path/to_test.dart  # run a single test file
fvm flutter analyze                    # lint (flutter_lints)
fvm flutter build apk                  # Android release build
fvm flutter build ipa                  # iOS release build
```

No code generation (no `build_runner`, `freezed`, or `json_serializable`). Models are hand-written `Equatable` classes with manual `fromJson`/`toInsertJson`.

## Architecture

### Feature-first structure

All business logic lives under `lib/features/<feature>/`, with three sub-layers per feature:

- `datasource/` — direct Supabase calls (no repository abstraction layer)
- `cubit/` or `bloc/` — state management (BLoC for complex event-driven features like `transactions`, Cubit for simpler ones)
- `view/` — full-screen widgets; `widgets/` — reusable sub-components

Cross-cutting code:
- `lib/core/models/` — Equatable data models with `fromJson`/`toInsertJson`
- `lib/core/constants/` — `SupabaseTables`, `SupabaseBuckets`, `SupabaseFunctions`, `enums.dart`
- `lib/core/utils/` — formatters and validators
- `lib/shared/widgets/` — app-wide reusable widgets
- `lib/app/` — `router.dart` (GoRouter), `app.dart` (root widget), `theme/`

### Supabase integration

The global Supabase client is exposed as `supabase` from `lib/main.dart`. Datasources accept an optional `SupabaseClient` for testability (default: `Supabase.instance.client`).

Backend resources:
- Tables: `transactions`, `accounts`, `categories`, `budgets`, `receipt_line_items`, `monthly_snapshots`
- Views: `account_balances`, `monthly_category_summary`
- Storage bucket: `receipts` — receipt images stored at `{user_id}/{uuid}.jpg`; accessed via signed URLs (1-hour expiry)
- Edge Functions: `process-receipt` (OCR via `ScannerDatasource.processReceipt`; calls the third-party **Tabscanner** receipt OCR API), `generate-monthly-snapshot`. Edge function source is **not in this repo** — it lives only in the Supabase project (Dashboard → Edge Functions)

`SUPABASE_URL` and `SUPABASE_ANON_KEY` have hard-coded defaults in [main.dart:15-17](lib/main.dart) — the app runs out of the box without any `--dart-define`. The anon key is intentionally committed (RLS protects data, not the key). Override only for non-default Supabase projects.

### Media & scanner deps

Scanner flow captures with `cunning_document_scanner` (ML Kit document scanner on Android, VisionKit on iOS — edge detection + auto-crop), picks from gallery with `image_picker`, and renders PDF receipts with `pdfx`. `file_picker` handles arbitrary attachments. `fl_chart` powers reports. OCR itself runs server-side: `process-receipt` sends the uploaded image to the Tabscanner API; there is no on-device text recognition.

The document scanner requires Android minSdk 24 (Flutter's default) and iOS 13 (`platform :ios, '13.0'` in `ios/Podfile`). On Android, ML Kit needs Google Play Services; without it the plugin falls back to a manual-crop scanner. On iOS the output is forced to JPEG because `ScannerDatasource.uploadImage` uploads as `image/jpeg`.

### State management conventions

- **Transactions** uses full BLoC (`TransactionBloc`) with typed events; `SearchTransactions` applies a manual 300ms debounce transformer (no rxdart)
- Other features use **Cubit**
- `amount` in `TransactionModel` is always positive; display sign comes from `TransType` (expense = −1, income = +1, transfer = 0)
- Joined relations (`accounts`, `categories`) are populated in `fromJson` when a JOIN query is used

### Navigation

GoRouter with auth redirect: unauthenticated users are sent to `/login`; authenticated users skip auth routes to `/home`. `_AuthRefreshNotifier` in `router.dart` drives reactive redirects from Supabase auth stream.

Shell route (`MainShell`) wraps the four tab destinations: `/home`, `/reports`, `/budgets`, `/settings`. Top-level routes (`/accounts`, `/transactions`, `/scanner`, `/scanner/review`) render above the shell.

Detail and review routes use `state.extra` to pass typed objects, not URL params:
- `/transactions/:id` expects `extra: TransactionModel`; if missing it post-frame redirects to `/transactions` ([router.dart:94-108](lib/app/router.dart))
- `/scanner/review` expects `extra: {'imagePath': String}`

Deep links that arrive without `extra` will fall back; do not rely on the `:id` path segment alone to hydrate a transaction.

Pages that must be reachable while logged out, such as `LegalScreen` (privacy policy and terms), are pushed with `Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(...))` rather than registered as GoRouter routes, because the auth redirect would send them to `/login`.

### Bottom sheets & snackbars

`showErrorSnackbar` uses the root `ScaffoldMessenger`, which renders *behind* a modal bottom sheet. Inside a sheet, either wrap its content in a local `ScaffoldMessenger` + `Scaffold` (as `AddTransactionSheet` does via `_scaffoldKey`) or show the error inline (as `SetBudgetSheet` does). Success toasts shown after `Navigator.pop` should still use the caller's (root) context.

### Testing

Tests use `bloc_test` + `mocktail`. Mock datasources by implementing the datasource class with mocktail stubs.
