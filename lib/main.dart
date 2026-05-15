import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/routing/app_router.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }
  }

  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl != null &&
        supabaseKey != null &&
        supabaseUrl.isNotEmpty &&
        supabaseKey.isNotEmpty) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    } else {
      debugPrint(
        'Warning: Supabase credentials missing. App will run in limited mode without backend.',
      );
    }
  } catch (e) {
    debugPrint('Warning: Could not initialize Supabase: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PULSO - Community Social App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
