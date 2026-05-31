import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_router.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);

  final supabaseUrl = _configValue(
    const String.fromEnvironment('SUPABASE_URL'),
    dotenv.env['SUPABASE_URL'],
  );
  final supabaseKey = _configValue(
    const String.fromEnvironment('SUPABASE_ANON_KEY'),
    dotenv.env['SUPABASE_ANON_KEY'],
  );

  if (supabaseUrl != null &&
      supabaseKey != null &&
      supabaseUrl.isNotEmpty &&
      supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  } else {
    debugPrint('Supabase credentials missing');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PULSO - Community Social App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

String? _configValue(String dartDefineValue, String? envValue) {
  final cleanDartDefine = dartDefineValue.trim();
  if (cleanDartDefine.isNotEmpty) {
    return cleanDartDefine;
  }

  final cleanEnvValue = envValue?.trim();
  return cleanEnvValue?.isNotEmpty == true ? cleanEnvValue : null;
}
