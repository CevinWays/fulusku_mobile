import 'package:equatable/equatable.dart';

/// Hasil OCR dari Edge Function `process-receipt`.
/// Bukan tabel di database — ini DTO untuk response Edge Function.
class ReceiptResultModel extends Equatable {
  final String? merchantName;
  final double? totalAmount;
  final double? taxAmount;
  final DateTime? transactionDate;
  final double? confidenceScore; // 0.0 - 1.0
  final List<LineItemModel> lineItems;

  /// URL gambar struk asli (jika sudah di-upload ke Storage).
  final String? rawImageUrl;

  const ReceiptResultModel({
    this.merchantName,
    this.totalAmount,
    this.taxAmount,
    this.transactionDate,
    this.confidenceScore,
    this.lineItems = const [],
    this.rawImageUrl,
  });

  /// Parse dari response Edge Function:
  /// `{ "success": true, "data": { ... } }` → kirim object `data` ke sini.
  factory ReceiptResultModel.fromJson(
    Map<String, dynamic> json, {
    String? rawImageUrl,
  }) {
    return ReceiptResultModel(
      merchantName: json['merchant_name'] as String?,
      totalAmount: _toDoubleOrNull(json['total_amount']),
      taxAmount: _toDoubleOrNull(json['tax_amount']),
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'] as String)
          : null,
      confidenceScore: _toDoubleOrNull(json['confidence_score']),
      lineItems: (json['line_items'] as List? ?? [])
          .map((e) => LineItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawImageUrl: rawImageUrl,
    );
  }

  /// Hasil kosong — untuk fallback saat OCR gagal & user input manual.
  factory ReceiptResultModel.empty({String? rawImageUrl}) =>
      ReceiptResultModel(rawImageUrl: rawImageUrl);

  ReceiptResultModel copyWith({
    String? merchantName,
    double? totalAmount,
    double? taxAmount,
    DateTime? transactionDate,
    double? confidenceScore,
    List<LineItemModel>? lineItems,
    String? rawImageUrl,
  }) {
    return ReceiptResultModel(
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      lineItems: lineItems ?? this.lineItems,
      rawImageUrl: rawImageUrl ?? this.rawImageUrl,
    );
  }

  @override
  List<Object?> get props => [
        merchantName,
        totalAmount,
        taxAmount,
        transactionDate,
        confidenceScore,
        lineItems,
        rawImageUrl,
      ];
}

/// Item per baris di struk (dari OCR).
/// Mapping ke tabel `receipt_line_items` saat tersimpan.
class LineItemModel extends Equatable {
  final int? id; // null saat belum tersimpan
  final int? transactionId; // null saat belum tersimpan
  final String description;
  final double? quantity;
  final double? unitPrice;
  final double totalPrice;

  const LineItemModel({
    this.id,
    this.transactionId,
    required this.description,
    this.quantity,
    this.unitPrice,
    required this.totalPrice,
  });

  factory LineItemModel.fromJson(Map<String, dynamic> json) {
    return LineItemModel(
      id: json['id'] as int?,
      transactionId: json['transaction_id'] as int?,
      description: (json['description'] as String?) ?? '',
      quantity: _toDoubleOrNull(json['quantity']),
      unitPrice: _toDoubleOrNull(json['unit_price']),
      totalPrice: _toDoubleOrNull(json['total_price']) ?? 0,
    );
  }

  /// Untuk INSERT ke `receipt_line_items` — butuh transaction_id.
  Map<String, dynamic> toInsertJson(int txId) => {
        'transaction_id': txId,
        'description': description,
        if (quantity != null) 'quantity': quantity,
        if (unitPrice != null) 'unit_price': unitPrice,
        'total_price': totalPrice,
      };

  @override
  List<Object?> get props =>
      [id, transactionId, description, quantity, unitPrice, totalPrice];
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
