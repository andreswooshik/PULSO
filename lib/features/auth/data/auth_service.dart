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
    required String identifier,
    required String password,
  }) async {
    final email = await _resolveEmailForSignIn(identifier);

    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String accountType,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'username': _normalizeUsername(username),
        'account_type': accountType,
      },
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await _client.rpc(
        'is_username_available',
        params: {'requested_username': _normalizeUsername(username)},
      );

      if (result is bool) {
        return result;
      }

      throw const AuthServiceException(
        'Could not check username availability. Please try again.',
      );
    } on AuthServiceException {
      rethrow;
    } catch (_) {
      throw const AuthServiceException(
        'Could not check username availability. Please try again.',
      );
    }
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<String> _resolveEmailForSignIn(String identifier) async {
    final cleanIdentifier = identifier.trim();
    if (_isEmail(cleanIdentifier)) {
      return cleanIdentifier;
    }

    try {
      final result = await _client.rpc(
        'get_email_by_username',
        params: {'requested_username': _normalizeUsername(cleanIdentifier)},
      );

      if (result is String && result.trim().isNotEmpty) {
        return result.trim();
      }

      throw const AuthServiceException('No account found for that username.');
    } on AuthServiceException {
      rethrow;
    } catch (_) {
      throw const AuthServiceException(
        'Could not find an account with that username.',
      );
    }
  }

  bool _isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
