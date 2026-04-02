import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme_builder.dart';
import 'core/theme/app_theme_data.dart';
import 'shared/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
