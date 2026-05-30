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

  Future<AuthResponse> signInWithEmailOrUsername({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();

    String loginEmail = cleanIdentifier;

    // If identifier is not an email, assume it is a username and look up the email
    if (!_isEmail(cleanIdentifier)) {
      final cleanUsername = _normalizeUsername(cleanIdentifier);
      try {
        final response = await _client.rpc(
          'get_email_by_username',
          params: {'requested_username': cleanUsername},
        );

        final resolvedEmail = response?.toString().trim();
        if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
          loginEmail = resolvedEmail;
        } else {
          // If RPC returns null or we can't find it, Supabase will just fail the login attempt
          // Or we can throw an explicit error.
          throw const AuthServiceException('Username not found or invalid.');
        }
      } catch (e) {
        if (e is AuthServiceException) rethrow; // Pass up known exception
        throw AuthServiceException(
          'Could not resolve username. Please ensure the database setup is complete or try using an email.',
        );
      }
    }

    return _client.auth.signInWithPassword(
      email: loginEmail,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String gender,
    required String birthday,
    required String username,
    required String email,
    required String password,
    required String accountType,
    String? middleInitial,
    String? suffix,
  }) {
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanMiddleInitial = middleInitial
        ?.trim()
        .replaceAll('.', '')
        .toUpperCase();
    final cleanSuffix = suffix?.trim();
    final fullName = [
      cleanFirstName,
      if (cleanMiddleInitial != null && cleanMiddleInitial.isNotEmpty)
        '$cleanMiddleInitial.',
      cleanLastName,
      if (cleanSuffix != null && cleanSuffix.isNotEmpty) cleanSuffix,
    ].join(' ');

    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'first_name': cleanFirstName,
        'middle_initial': cleanMiddleInitial,
        'last_name': cleanLastName,
        'suffix': cleanSuffix,
        'gender': gender.trim(),
        'birthday': birthday.trim(),
        'full_name': fullName,
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
