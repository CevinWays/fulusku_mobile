import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

typedef LegalSection = (String heading, String body);

/// Halaman teks legal (Kebijakan Privasi / Ketentuan Layanan).
class LegalScreen extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;

  const LegalScreen({super.key, required this.title, required this.sections});

  /// Push langsung (bukan route GoRouter) agar bisa dibuka dari layar
  /// register tanpa kena redirect auth ke /login.
  static void open(
    BuildContext context,
    String title,
    List<LegalSection> sections,
  ) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => LegalScreen(title: title, sections: sections),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('Terakhir diperbarui: $legalLastUpdated',
              style: AppTypography.caption),
          for (final (heading, body) in sections) ...[
            const SizedBox(height: 20),
            Text(heading, style: AppTypography.heading3),
            const SizedBox(height: 8),
            Text(body, style: AppTypography.body.copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}

// DRAF — wajib ditinjau legal & semua [PLACEHOLDER] diisi sebelum rilis.
const legalLastUpdated = '2 November 2026';

const List<LegalSection> privacyPolicy = [
  (
    'Pendahuluan',
    'Kebijakan Privasi ini menjelaskan bagaimana [NAMA PERUSAHAAN] ("kami") '
        'mengumpulkan, menggunakan, menyimpan, dan melindungi data pribadi kamu '
        'saat menggunakan aplikasi Fulusku, sesuai Undang-Undang Nomor 27 Tahun '
        '2022 tentang Pelindungan Data Pribadi (UU PDP).',
  ),
  (
    'Data yang Kami Kumpulkan',
    '• Data akun: nama dan alamat email.\n'
        '• Data keuangan: akun/dompet, saldo, transaksi, kategori, dan anggaran '
        'yang kamu catat.\n'
        '• Foto atau file struk yang kamu unggah, beserta hasil pembacaannya '
        '(nama toko, tanggal, total, rincian item).\n\n'
        'Data keuangan pribadi termasuk data pribadi yang bersifat spesifik '
        'menurut UU PDP, sehingga kami memprosesnya dengan perlindungan tambahan.',
  ),
  (
    'Dasar dan Tujuan Pemrosesan',
    'Kami memproses data berdasarkan persetujuan kamu dan untuk menjalankan '
        'layanan, yaitu untuk:\n'
        '• membuat dan mengelola akun kamu;\n'
        '• mencatat, menampilkan, dan meringkas keuangan kamu;\n'
        '• membaca isi struk secara otomatis (OCR);\n'
        '• menjaga keamanan dan memperbaiki layanan.\n\n'
        'Kami tidak menjual data pribadi kamu dan tidak menggunakannya untuk iklan.',
  ),
  (
    'Pihak Ketiga',
    'Kami menggunakan penyedia layanan berikut untuk menjalankan aplikasi:\n'
        '• Supabase: autentikasi, database, dan penyimpanan file struk.\n'
        '• Tabscanner: pembacaan teks dari foto struk (OCR). Foto struk '
        'dikirim ke server Tabscanner untuk diproses.\n\n'
        'Pemindaian dokumen di perangkat menggunakan fitur sistem '
        '(Google ML Kit di Android, VisionKit di iOS). Penyedia hanya memproses '
        'data sesuai instruksi kami.',
  ),
  (
    'Transfer Data ke Luar Negeri',
    'Data kamu disimpan di server yang berlokasi di Indonesia. Jika lokasi '
        'tersebut berada di luar Indonesia, kami memastikan tingkat pelindungan '
        'data yang setara sesuai ketentuan UU PDP.',
  ),
  (
    'Penyimpanan dan Keamanan',
    'Data disimpan selama akun kamu aktif. Setelah akun dihapus, data akan '
        'dihapus dalam 30 hari, kecuali diwajibkan lain oleh hukum. Akses '
        'data dibatasi per pengguna, dan foto struk hanya dapat dibuka melalui '
        'tautan sementara.',
  ),
  (
    'Hak Kamu',
    'Sebagai subjek data, kamu berhak untuk:\n'
        '• mengakses dan memperoleh salinan data pribadi kamu;\n'
        '• memperbaiki data yang tidak akurat;\n'
        '• menghapus data atau akun kamu;\n'
        '• menarik kembali persetujuan pemrosesan data.\n\n'
        'Ajukan permintaan melalui kontak di bawah.',
  ),
  (
    'Perubahan Kebijakan',
    'Kami dapat memperbarui kebijakan ini dari waktu ke waktu. Perubahan penting '
        'akan kami beritahukan melalui aplikasi.',
  ),
  (
    'Kontak',
    'Cevin Ways Al Cornelis\nJl Raya Candi VD no 226 Kota Malang\nEmail: cevinways34@gmail.com',
  ),
];

const List<LegalSection> termsOfService = [
  (
    'Penerimaan Ketentuan',
    'Dengan membuat akun atau menggunakan Fulusku, kamu menyetujui Ketentuan '
        'Layanan ini dan Kebijakan Privasi kami. Jika tidak setuju, mohon tidak '
        'menggunakan aplikasi.',
  ),
  (
    'Layanan',
    'Fulusku adalah aplikasi pencatatan keuangan pribadi yang membantu kamu '
        'mencatat transaksi, mengatur anggaran, dan membaca struk secara otomatis. '
        'Fulusku bukan bank, dompet digital, atau penyedia jasa keuangan, dan tidak '
        'memindahkan uang.',
  ),
  (
    'Akun',
    'Kamu bertanggung jawab menjaga kerahasiaan akun dan kata sandi, serta atas '
        'semua aktivitas di akun kamu. Berikan informasi yang benar saat mendaftar.',
  ),
  (
    'Hasil Pembacaan Struk',
    'Pembacaan struk otomatis (OCR) dapat keliru. Kamu wajib memeriksa dan '
        'mengoreksi nominal, tanggal, dan detail lain sebelum menyimpan transaksi.',
  ),
  (
    'Bukan Nasihat Keuangan',
    'Informasi, ringkasan, dan laporan di Fulusku hanya untuk membantu pencatatan '
        'dan bukan merupakan nasihat keuangan, investasi, atau perpajakan.',
  ),
  (
    'Penggunaan yang Dilarang',
    'Kamu tidak boleh menggunakan Fulusku untuk aktivitas yang melanggar hukum, '
        'mengganggu atau mencoba membobol sistem, maupun mengakses data pengguna lain.',
  ),
  (
    'Batasan Tanggung Jawab',
    'Layanan disediakan "sebagaimana adanya". Sepanjang diizinkan hukum, '
        '[NAMA PERUSAHAAN] tidak bertanggung jawab atas kerugian akibat data yang '
        'tidak akurat, gangguan layanan, atau keputusan yang kamu ambil berdasarkan '
        'informasi di aplikasi.',
  ),
  (
    'Perubahan dan Penghentian',
    'Kami dapat mengubah, menangguhkan, atau menghentikan sebagian layanan, serta '
        'memperbarui ketentuan ini. Kamu dapat berhenti menggunakan layanan dan '
        'meminta penghapusan akun kapan saja.',
  ),
  (
    'Hukum yang Berlaku',
    'Ketentuan ini diatur oleh hukum Republik Indonesia.',
  ),
  (
    'Kontak',
    '[NAMA PERUSAHAAN]\n[ALAMAT]\nEmail: [EMAIL KONTAK]',
  ),
];
