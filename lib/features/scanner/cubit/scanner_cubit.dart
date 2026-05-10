import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../datasource/scanner_datasource.dart';
import 'scanner_state.dart';

class ScannerCubit extends Cubit<ScannerState> {
  final ScannerDatasource _datasource;

  ScannerCubit(this._datasource) : super(const ScannerIdle());

  /// Upload gambar lalu panggil OCR.
  Future<void> uploadAndProcess(File imageFile) async {
    emit(const ScannerUploading());
    try {
      final path = await _datasource.uploadImage(imageFile);

      emit(const ScannerProcessing());
      // Artificial delay untuk psychological confidence (Plan 06 spec).
      await Future.delayed(const Duration(milliseconds: 150));

      final result = await _datasource.processReceipt(path);
      final signedUrl = await _datasource.getSignedUrl(path);

      emit(ScannerReview(
        result: result.copyWith(rawImageUrl: path),
        imageUrl: signedUrl,
      ));
    } catch (e) {
      emit(ScannerError('Gagal memproses struk: $e'));
    }
  }

  void reset() => emit(const ScannerIdle());
}
