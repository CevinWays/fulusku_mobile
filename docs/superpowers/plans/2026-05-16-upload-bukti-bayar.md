# Upload Bukti Bayar (PDF & Image) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tambah opsi "Upload PDF" di CameraScreen agar user bisa upload nota PDF dari storage lokal, di-convert ke JPEG di Flutter (page 1), lalu diproses OCR via Edge Function yang sudah ada.

**Architecture:** Extend `CameraScreen` dengan method `_pickPdf()` yang menggunakan `file_picker` untuk memilih PDF dan `pdfx` untuk render page 1 ke JPEG. File hasil render dikirim ke `ScannerCubit.uploadAndProcess()` — path yang sama persis dengan flow kamera/galeri yang sudah ada. Tidak ada perubahan ke datasource, cubit, edge function, atau flow input manual.

**Tech Stack:** Flutter, `pdfx ^2.9.2`, `file_picker ^11.0.2`, `path_provider` (sudah ada), `uuid` (sudah ada), `ScannerCubit` (sudah ada)

---

## File Map

| File | Action | Tanggung Jawab |
|------|--------|----------------|
| `pubspec.yaml` | Modify | Tambah `pdfx` dan `file_picker` |
| `lib/features/scanner/view/camera_screen.dart` | Modify | Tambah `_pickPdf()` + tombol "Upload PDF" |
| `test/features/scanner/view/camera_screen_test.dart` | Create | Widget test: verifikasi tombol "Upload PDF" muncul |

---

### Task 1: Tambah Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Tambah `pdfx` dan `file_picker` ke pubspec**

  Buka `pubspec.yaml`, di bawah `image_cropper: ^8.0.2` tambahkan:

  ```yaml
  # Camera & Image
  camera: ^0.11.0+2
  image_picker: ^1.1.2
  image_cropper: ^8.0.2
  pdfx: ^2.9.2
  file_picker: ^11.0.2
  ```

- [ ] **Step 2: Install dependencies**

  ```bash
  flutter pub get
  ```

  Expected output: `Got dependencies!` tanpa error.

- [ ] **Step 3: Verifikasi tidak ada conflict**

  ```bash
  flutter pub outdated
  ```

  Expected: tidak ada baris merah (breaking incompatibility).

- [ ] **Step 4: Commit**

  ```bash
  git add pubspec.yaml pubspec.lock
  git commit -m "chore: add pdfx and file_picker dependencies"
  ```

---

### Task 2: Widget Test — Tombol "Upload PDF" Ada di UI

**Files:**
- Create: `test/features/scanner/view/camera_screen_test.dart`

- [ ] **Step 1: Buat file test**

  Buat `test/features/scanner/view/camera_screen_test.dart`:

  ```dart
  import 'package:bloc_test/bloc_test.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mocktail/mocktail.dart';

  import 'package:fulusku/features/scanner/cubit/scanner_cubit.dart';
  import 'package:fulusku/features/scanner/cubit/scanner_state.dart';
  import 'package:fulusku/features/scanner/view/camera_screen.dart';

  class MockScannerCubit extends MockCubit<ScannerState>
      implements ScannerCubit {}

  Widget _buildSubject(ScannerCubit cubit) {
    return MaterialApp(
      home: BlocProvider<ScannerCubit>.value(
        value: cubit,
        child: const CameraScreen(),
      ),
    );
  }

  void main() {
    late MockScannerCubit cubit;

    setUp(() {
      cubit = MockScannerCubit();
      when(() => cubit.state).thenReturn(const ScannerIdle());
    });

    group('CameraScreen', () {
      testWidgets('shows Upload PDF button in idle state', (tester) async {
        await tester.pumpWidget(_buildSubject(cubit));
        expect(find.text('Upload PDF'), findsOneWidget);
      });

      testWidgets('shows Buka Kamera button in idle state', (tester) async {
        await tester.pumpWidget(_buildSubject(cubit));
        expect(find.text('Buka Kamera'), findsOneWidget);
      });

      testWidgets('shows Pilih dari Galeri button in idle state', (tester) async {
        await tester.pumpWidget(_buildSubject(cubit));
        expect(find.text('Pilih dari Galeri'), findsOneWidget);
      });

      testWidgets('hides action buttons while uploading', (tester) async {
        when(() => cubit.state).thenReturn(const ScannerUploading());
        when(() => cubit.stream)
            .thenAnswer((_) => Stream.value(const ScannerUploading()));
        await tester.pumpWidget(_buildSubject(cubit));
        expect(find.text('Upload PDF'), findsNothing);
        expect(find.text('Buka Kamera'), findsNothing);
      });

      testWidgets('hides action buttons while processing', (tester) async {
        when(() => cubit.state).thenReturn(const ScannerProcessing());
        when(() => cubit.stream)
            .thenAnswer((_) => Stream.value(const ScannerProcessing()));
        await tester.pumpWidget(_buildSubject(cubit));
        expect(find.text('Upload PDF'), findsNothing);
      });
    });
  }
  ```

- [ ] **Step 2: Jalankan test — pastikan FAIL dulu**

  ```bash
  flutter test test/features/scanner/view/camera_screen_test.dart --name "shows Upload PDF button"
  ```

  Expected: **FAIL** — "Upload PDF" belum ada di UI.

---

### Task 3: Implementasi `_pickPdf()` + UI di CameraScreen

**Files:**
- Modify: `lib/features/scanner/view/camera_screen.dart`

- [ ] **Step 1: Ganti seluruh imports di atas file menjadi**

  ```dart
  import 'dart:io';

  import 'package:file_picker/file_picker.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:go_router/go_router.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:pdfx/pdfx.dart';
  import 'package:uuid/uuid.dart';

  import '../../../app/theme/app_colors.dart';
  import '../../../shared/widgets/error_snackbar.dart';
  import '../cubit/scanner_cubit.dart';
  import '../cubit/scanner_state.dart';
  ```

- [ ] **Step 2: Tambah method `_pickPdf()` setelah `_pickFromGallery()`**

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

- [ ] **Step 3: Tambah tombol "Upload PDF" di UI**

  Di dalam blok `else` (saat idle, setelah `TextButton.icon` untuk "Pilih dari Galeri"), tambahkan:

  ```dart
  TextButton.icon(
    onPressed: _pickFromGallery,
    icon: const Icon(Icons.photo_library_rounded,
        color: Colors.white70),
    label: const Text(
      'Pilih dari Galeri',
      style: TextStyle(color: Colors.white70),
    ),
  ),
  const SizedBox(height: 8),
  TextButton.icon(
    onPressed: _pickPdf,
    icon: const Icon(Icons.picture_as_pdf_rounded,
        color: Colors.white70),
    label: const Text(
      'Upload PDF',
      style: TextStyle(color: Colors.white70),
    ),
  ),
  ```

- [ ] **Step 4: Verifikasi analyze clean**

  ```bash
  flutter analyze lib/features/scanner/view/camera_screen.dart
  ```

  Expected: `No issues found!`

---

### Task 4: Jalankan Test + Commit

- [ ] **Step 1: Jalankan semua test camera_screen**

  ```bash
  flutter test test/features/scanner/view/camera_screen_test.dart -v
  ```

  Expected: semua 5 test **PASS**.

- [ ] **Step 2: Jalankan full test suite**

  ```bash
  flutter test
  ```

  Expected: semua test pass, tidak ada regresi.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/features/scanner/view/camera_screen.dart \
          test/features/scanner/view/camera_screen_test.dart
  git commit -m "feat: add PDF upload option to CameraScreen

  - Add _pickPdf(): file_picker → pdfx render page 1 → JPEG temp file
  - Feed temp file to existing uploadAndProcess() flow (unchanged)
  - Add Upload PDF TextButton alongside Kamera & Galeri options
  - Widget tests for all 3 buttons + loading state hiding

  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
  ```

---

### Task 5: Manual Smoke Test (Device/Emulator)

- [ ] **Step 1: Run di device**

  ```bash
  flutter run
  ```

- [ ] **Step 2: Verifikasi flow kamera tidak rusak**

  FAB → Pindai Struk → Buka Kamera → ambil foto → pastikan muncul ReviewScreen dengan data OCR.

- [ ] **Step 3: Verifikasi flow galeri tidak rusak**

  FAB → Pindai Struk → Pilih dari Galeri → pilih image → pastikan muncul ReviewScreen.

- [ ] **Step 4: Verifikasi flow PDF**

  FAB → Pindai Struk → Upload PDF → pilih `.pdf` dari storage → pastikan loading indicator muncul → pastikan ReviewScreen muncul dengan data OCR.

- [ ] **Step 5: Verifikasi input manual tidak rusak**

  FAB → Input Manual → isi form → simpan → pastikan transaksi tersimpan normal.

- [ ] **Step 6: Verifikasi error handling**

  Jika ada PDF corrupt/tidak bisa dibuka, pastikan muncul snackbar `"Gagal baca PDF: ..."` dan user tetap di CameraScreen.
