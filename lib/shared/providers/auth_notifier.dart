import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An error occurred');
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String? fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, fullName: fullName ?? '');
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An error occurred');
      return false;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An error occurred');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}