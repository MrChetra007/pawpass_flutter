import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme_builder.dart';
import 'core/theme/app_theme_data.dart';
import 'shared/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String supabaseUrl = '';
  String supabaseAnonKey = '';
  
  try {
    final data = await rootBundle.loadString('.env');
    for (final line in data.split('\n')) {
      if (line.trim().isNotEmpty && !line.startsWith('#')) {
        final parts = line.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          if (key == 'SUPABASE_URL') supabaseUrl = value;
          if (key == 'SUPABASE_ANON_KEY') supabaseAnonKey = value;
        }
      }
    }
  } catch (e) {
    debugPrint('Error loading .env: $e');
  }

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not found');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PawPassApp(),
    ),
  );
}

class PawPassApp extends ConsumerWidget {
  const PawPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeKey = ref.watch(themeNotifierProvider);
    final themeData = PawThemeData.all[themeKey]!;
    final router = ref.watch(routerProvider);

    return AnimatedTheme(
      data: AppThemeBuilder.build(themeData),
      duration: const Duration(milliseconds: 300),
      child: MaterialApp.router(
        title: 'PawPass',
        debugShowCheckedModeBanner: false,
        theme: AppThemeBuilder.build(themeData),
        routerConfig: router,
      ),
    );
  }
}
