import 'package:equatable/equatable.dart';

import '../../../core/models/receipt_result_model.dart';

sealed class ScannerState extends Equatable {
  const ScannerState();
  @override
  List<Object?> get props => [];
}

class ScannerIdle extends ScannerState {
  const ScannerIdle();
}

class ScannerUploading extends ScannerState {
  const ScannerUploading();
}

class ScannerProcessing extends ScannerState {
  const ScannerProcessing();
}

class ScannerReview extends ScannerState {
  final ReceiptResultModel result;
  final String imageUrl;

  const ScannerReview({required this.result, required this.imageUrl});

  @override
  List<Object?> get props => [result, imageUrl];
}

class ScannerConfirmed extends ScannerState {
  final ReceiptResultModel result;
  const ScannerConfirmed(this.result);
  @override
  List<Object?> get props => [result];
}

class ScannerError extends ScannerState {
  final String message;
  const ScannerError(this.message);
  @override
  List<Object?> get props => [message];
}
