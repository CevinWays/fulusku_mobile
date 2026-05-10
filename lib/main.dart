import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';

/// Supabase URL & anon key.
///
/// Dapat di-override saat build via:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Default-nya menunjuk ke project fulusku — anon key memang public/aman
/// di-commit (RLS yang melindungi data, bukan key).
const _defaultSupabaseUrl = 'https://lsoqxjbgzndqfxmwgmzk.supabase.co';
const _defaultSupabaseAnonKey =
    'sb_publishable_u9C0eCCsyoKZhIodnqTJfg_Pv04w9B4';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: _defaultSupabaseUrl,
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: _defaultSupabaseAnonKey,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation ke portrait untuk MVP (UI dirancang untuk portrait).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inisialisasi locale Indonesia untuk DateFormat & NumberFormat.
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase client.
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const FuluskuApp());
}

/// Shortcut akses ke Supabase client di seluruh app.
final supabase = Supabase.instance.client;
