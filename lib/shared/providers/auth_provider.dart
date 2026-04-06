import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void initGoogleSignIn() {
  final webClientId = dotenv.env['WEB_CLIENT_ID'];
  final iosClientId = dotenv.env['IOS_CLIENT_ID'];
  final androidClientId = dotenv.env['ANDROID_CLIENT_ID'];

  unawaited(
    GoogleSignIn.instance
        .initialize(
          clientId: Platform.isIOS ? iosClientId : androidClientId,
          serverClientId: webClientId,
        )
        .then((_) {
          GoogleSignIn.instance.attemptLightweightAuthentication();
        }),
  );
}

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.session?.user,
  );
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    Supabase.instance.client,
    ref.watch(googleSignInProvider),
  );
});

class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._supabase, this._googleSignIn);

  User? get currentUser => _supabase.auth.currentUser;

  Future<bool> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'pawpass://login-callback',
    );
    return true;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) {
    return _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.auth.admin.deleteUser(user.id);
    }
  }
}
