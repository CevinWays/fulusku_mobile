# Upload Bukti Bayar (PDF & Image dari Local)

**Date:** 2026-05-16  
**Status:** Approved

## Problem

User hanya bisa pindai struk via kamera. Tidak ada cara upload nota dari penyimpanan
lokal HP — baik image (galeri) maupun PDF.

## Goals

- User bisa pilih **image dari galeri** atau **file PDF** dari storage lokal
- PDF di-convert ke image (page 1) di Flutter sebelum dikirim ke OCR
- OCR flow (Edge Function `process-receipt`) tidak berubah
- Fitur **input manual tidak disentuh**

## Out of Scope

- Upload PDF multi-halaman (hanya page 1 otomatis)
- Perubahan Supabase Edge Function
- Perubahan `scanner_datasource.dart`, `scanner_cubit.dart`, `scanner_state.dart`
- Perubahan `review_screen.dart`, `add_transaction_sheet.dart`, `main_shell.dart`

---

## Architecture

### Entry Points (setelah perubahan)

```
FAB (MainShell)
├── Input Manual → AddTransactionSheet          [UNCHANGED]
└── Pindai Struk → CameraScreen
    ├── Buka Kamera    ─┐
    ├── Pilih Galeri    ├─→ ScannerCubit.uploadAndProcess(File) → ReviewScreen
    └── Upload PDF    ─┘
```

Semua 3 jalur scanner masuk ke `uploadAndProcess()` yang sama.

### PDF Conversion Flow

```
user tap "Upload PDF"
  → FilePicker (filter: .pdf)
  → pdfx: render page 1 → Uint8List (JPEG format)
  → save ke temp File di getTemporaryDirectory()
  → ScannerCubit.uploadAndProcess(tempFile)   ← identical ke flow kamera
```

---

## Dependencies Baru

| Package | Version | Fungsi |
|---------|---------|--------|
| `pdfx` | latest stable | Render PDF page → image (Uint8List) |
| `file_picker` | latest stable | File picker dengan filter .pdf |

`path_provider` sudah ada di pubspec.

---

## Files Changed

| File | Perubahan |
|------|-----------|
| `pubspec.yaml` | + `pdfx`, + `file_picker` |
| `camera_screen.dart` | + `_pickPdf()` method + tombol "Upload PDF" di UI |

---

## CameraScreen — Detail Implementasi

### UI

Tambah tombol ketiga di bawah "Pilih dari Galeri":

```dart
TextButton.icon(
  onPressed: _pickPdf,
  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white70),
  label: const Text('Upload PDF', style: TextStyle(color: Colors.white70)),
),
```

### `_pickPdf()` method

```dart
Future<void> _pickPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (result == null || result.files.isEmpty || !mounted) return;

  final pdfPath = result.files.first.path;
  if (pdfPath == null) return;

  HapticFeedback.lightImpact();
  try {
    final doc = await PdfDocument.openFile(pdfPath);
    final page = await doc.getPage(1);
    final rendered = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();
    await doc.close();

    if (rendered == null || !mounted) return;

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${const Uuid().v4()}.jpg');
    await tempFile.writeAsBytes(rendered.bytes);

    if (!mounted) return;
    await context.read<ScannerCubit>().uploadAndProcess(tempFile);
  } catch (e) {
    if (mounted) showErrorSnackbar(context, 'Gagal baca PDF: $e');
  }
}
```

### Error Handling

- PDF tidak bisa dibuka / corrupt → snackbar error, user tetap di CameraScreen
- `rendered == null` (page kosong) → silent return
- Pattern sama dengan `_pickFromGallery()`

---

## What Does NOT Change

- `ScannerDatasource.uploadImage()` — tetap terima `File` JPEG, tidak perlu tahu sumber file
- `ScannerDatasource.processReceipt()` — tidak berubah
- Edge Function `process-receipt` — tidak berubah
- `AddTransactionSheet` input manual flow — tidak berubah
- `ReviewScreen` — tidak berubah
