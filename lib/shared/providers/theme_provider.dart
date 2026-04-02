import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme_data.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main()');
});

final themeNotifierProvider = NotifierProvider<ThemeNotifier, PawTheme>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<PawTheme> {
  static const _key = 'selected_theme';
  PawTheme _loadedTheme = PawTheme.forest;
  bool _initialized = false;

  @override
  PawTheme build() {
    if (!_initialized) {
      _initialized = true;
      _loadSaved();
    }
    return _loadedTheme;
  }

  PawTheme _loadSavedSync() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final saved = prefs.getString(_key);
      if (saved != null) {
        final theme = PawTheme.values.firstWhere(
          (t) => t.name == saved,
          orElse: () => PawTheme.forest,
        );
        return theme;
      }
    } catch (_) {}
    return PawTheme.forest;
  }

  Future<void> _loadSaved() async {
    final theme = _loadSavedSync();
    if (theme != _loadedTheme) {
      _loadedTheme = theme;
    }
  }

  Future<void> setTheme(PawTheme theme) async {
    _loadedTheme = theme;
    state = theme;
    
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_key, theme.name);
    } catch (_) {}

    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid != null) {
        await supabase.from('users').update({'theme': theme.name}).eq('id', uid);
      }
    } catch (_) {}
  }
}
