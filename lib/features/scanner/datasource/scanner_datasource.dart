import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/models/receipt_result_model.dart';

class ScannerDatasource {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  ScannerDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Upload gambar ke Storage. Return path: `{user_id}/{uuid}.jpg`.
  Future<String> uploadImage(File file) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/${_uuid.v4()}.jpg';
    await _client.storage.from(SupabaseBuckets.receipts).upload(
          path,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
    return path;
  }

  /// Generate signed URL untuk display gambar (expire 1 jam).
  Future<String> getSignedUrl(String path) async {
    final url = await _client.storage
        .from(SupabaseBuckets.receipts)
        .createSignedUrl(path, 3600);
    return url;
  }

  /// Panggil Edge Function `process-receipt`.
  /// Return [ReceiptResultModel] (mungkin dengan field null jika OCR gagal).
  Future<ReceiptResultModel> processReceipt(String imagePath) async {
    final response = await _client.functions.invoke(
      SupabaseFunctions.processReceipt,
      body: {'image_path': imagePath},
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Tidak ada response dari OCR.');
    }

    final success = data['success'] == true;
    if (!success) {
      // OCR gagal — return empty result agar user bisa input manual.
      return ReceiptResultModel.empty();
    }

    return ReceiptResultModel.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }
}
