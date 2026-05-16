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

/// Camera screen — pakai ImagePicker (system camera) untuk simplicity MVP.
/// Camera in-app dengan overlay panduan bisa di-upgrade post-MVP.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.imagePicker});
  final ImagePicker? imagePicker;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final _picker = widget.imagePicker ?? ImagePicker();
  bool _autoTriggered = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger camera saat screen open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoTriggered) {
        _autoTriggered = true;
        _capture();
      }
    });
  }

  Future<void> _capture() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) {
        // User cancel → kembali ke screen sebelumnya.
        if (mounted) Navigator.pop(context);
        return;
      }

      HapticFeedback.mediumImpact();
      if (!mounted) return;
      await context.read<ScannerCubit>().uploadAndProcess(File(picked.path));
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Gagal akses kamera: $e');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final pdfPath = result.files.single.path;
      if (pdfPath == null) return;

      final document = await PdfDocument.openFile(pdfPath);
      try {
        final page = await document.getPage(1);
        try {
          const maxRenderWidth = 1600.0;
          final scale = (maxRenderWidth / page.width).clamp(0.0, 2.0);
          final pageImage = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: PdfPageImageFormat.jpeg,
          );
          if (pageImage == null) return;

          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/${const Uuid().v4()}.jpg');
          await file.writeAsBytes(pageImage.bytes);

          if (!mounted) return;
          await context.read<ScannerCubit>().uploadAndProcess(file);
        } finally {
          await page.close();
        }
      } finally {
        await document.close();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Gagal membaca PDF: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;
      HapticFeedback.lightImpact();
      await context.read<ScannerCubit>().uploadAndProcess(File(picked.path));
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Gagal pilih gambar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScannerCubit, ScannerState>(
      listener: (context, state) {
        if (state is ScannerReview) {
          context.pushReplacement('/scanner/review', extra: {
            'imagePath': state.result.rawImageUrl,
          });
        }
        if (state is ScannerError) {
          showErrorSnackbar(context, state.message);
          context.read<ScannerCubit>().reset();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.textPrimary,
        body: SafeArea(
          child: BlocBuilder<ScannerCubit, ScannerState>(
            builder: (context, state) {
              return Stack(
                children: [
                  // Background placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.document_scanner_rounded,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        if (state is ScannerUploading || state is ScannerProcessing) ...[
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 24),
                          Text(
                            state is ScannerUploading
                                ? 'Mengunggah gambar...'
                                : 'Membaca isi struk...',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mohon tunggu sebentar',
                            style: TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ] else ...[
                          const Text(
                            'Pindai Struk',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Foto struk dengan pencahayaan cukup\ndan posisikan datar dalam bingkai.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _capture,
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Buka Kamera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_library_rounded,
                                color: Colors.white70),
                            label: const Text(
                              'Pilih dari Galeri',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: _pickPdf,
                            icon: const Icon(Icons.picture_as_pdf,
                                color: Colors.white70),
                            label: const Text(
                              'Upload PDF',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
