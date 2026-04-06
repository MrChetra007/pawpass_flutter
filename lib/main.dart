import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme_builder.dart';
import 'core/theme/app_theme_data.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not found');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  initGoogleSignIn();

  await NotificationService().initialize();
  _requestNotificationPermission();

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

Future<void> _requestNotificationPermission() async {
  final notificationService = NotificationService();
  final shouldRequest = await notificationService.shouldRequestPermission();
  
  if (shouldRequest) {
    await notificationService.requestPermission();
    await notificationService.markPermissionRequested();
  }
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
