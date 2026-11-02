# Fulusku

Aplikasi keuangan pribadi (Flutter) dengan scan struk otomatis, untuk pasar Indonesia.

## Menjalankan

Project memakai [FVM](https://fvm.app) (channel `stable`):

```bash
fvm flutter pub get
fvm flutter run
```

Kredensial Supabase sudah punya default di `lib/main.dart`. Untuk project lain, override dengan
`--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

```bash
fvm flutter analyze   # lint
fvm flutter test      # test
```

## Scan struk (OCR)

| Tahap | Di mana | Teknologi |
|---|---|---|
| Ambil foto struk | App | `cunning_document_scanner`: ML Kit Document Scanner (Android), VisionKit (iOS). Deteksi tepi + crop otomatis |
| Galeri / PDF | App | `image_picker`, `file_picker` + `pdfx` (halaman 1 → JPEG) |
| Upload | Supabase Storage | bucket `receipts`, path `{user_id}/{uuid}.jpg` |
| Baca isi struk | Supabase Edge Function `process-receipt` | **[Tabscanner](https://tabscanner.com) API** (OCR struk pihak ketiga) |
| Review hasil | App | `ReviewScreen`, lalu user konfirmasi sebelum transaksi disimpan |

Catatan:
- Source edge function **tidak ada di repo ini**. Lihat di Supabase Dashboard → Edge Functions → `process-receipt`.
- Foto struk dikirim ke server Tabscanner. Hal ini disebutkan di Kebijakan Privasi (`lib/features/settings/view/legal_screen.dart`).
- Syarat scanner: Android minSdk 24, iOS 13. Di Android, ML Kit butuh Google Play Services.

## Struktur

Lihat [CLAUDE.md](CLAUDE.md) untuk arsitektur (feature-first, BLoC/Cubit, GoRouter) dan konvensi kode.
