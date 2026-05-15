import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient? _clientOverride;

  const AuthService({SupabaseClient? client}) : _clientOverride = client;

  Supabase? get _supabase {
    try {
      return Supabase.instance;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable =>
      _clientOverride != null || (_supabase?.isInitialized ?? false);

  SupabaseClient get _client {
    final clientOverride = _clientOverride;
    if (clientOverride != null) {
      return clientOverride;
    }

    final supabase = _supabase;

    if (supabase == null || !supabase.isInitialized) {
      throw const AuthServiceException(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    return supabase.client;
  }

  Session? get currentSession {
    if (!isAvailable) {
      return null;
    }

    return _client.auth.currentSession;
  }

  Stream<AuthState> get authStateChanges {
    if (!isAvailable) {
      return const Stream<AuthState>.empty();
    }

    return _client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String accountType,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim(), 'account_type': accountType},
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
