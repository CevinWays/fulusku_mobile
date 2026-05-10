/// Validator email standar.
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email wajib diisi';
  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!regex.hasMatch(value)) return 'Format email tidak valid';
  return null;
}

/// Validator password — min 8 karakter (sesuai Supabase Auth setting).
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password wajib diisi';
  if (value.length < 8) return 'Password minimal 8 karakter';
  return null;
}

/// Validator field umum.
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) return '$fieldName wajib diisi';
  return null;
}

/// Validator nominal Rupiah. Menerima format `1500000`, `1.500.000`, dll.
String? validateAmount(String? value) {
  if (value == null || value.isEmpty) return 'Nominal wajib diisi';
  final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
  final amount = double.tryParse(cleaned);
  if (amount == null) return 'Nominal tidak valid';
  if (amount <= 0) return 'Nominal harus lebih dari 0';
  if (amount > 9999999999999.99) return 'Nominal terlalu besar';
  return null;
}

/// Validator konfirmasi password (sama dengan password awal).
String? validatePasswordMatch(String? value, String? original) {
  if (value == null || value.isEmpty) return 'Konfirmasi password wajib diisi';
  if (value != original) return 'Password tidak cocok';
  return null;
}
