import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme_data.dart';

class User {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String plan;
  final PawTheme theme;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.plan = 'free',
    this.theme = PawTheme.forest,
  });

  bool get isPro => plan == 'pro' || plan == 'family';
  bool get isFamily => plan == 'family';

  int get maxPets {
    switch (plan) {
      case 'pro':
        return 3;
      case 'family':
        return 999;
      default:
        return 1;
    }
  }

  int get maxRecords {
    switch (plan) {
      case 'pro':
      case 'family':
        return 999999;
      default:
        return 5;
    }
  }
}

final userProvider = FutureProvider<User?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return null;

  final response = await supabase
      .from('users')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return null;

  final themeName = response['theme'] as String? ?? 'forest';
  final theme = PawTheme.values.firstWhere(
    (t) => t.name == themeName,
    orElse: () => PawTheme.forest,
  );

  return User(
    id: user.id,
    email: user.email ?? '',
    fullName: response['full_name'] as String?,
    avatarUrl: response['avatar_url'] as String?,
    plan: response['plan'] as String? ?? 'free',
    theme: theme,
  );
});

final subscriptionProvider = FutureProvider<User?>((ref) {
  return ref.watch(userProvider.future);
});
