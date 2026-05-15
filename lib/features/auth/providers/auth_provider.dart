import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthScreenMode { login, signup }

enum AuthAccountType { personal, business, organization }

enum AuthRequestStatus { idle, loading, success, failure }

extension AuthAccountTypeLabel on AuthAccountType {
  String get label {
    return switch (this) {
      AuthAccountType.personal => 'personal',
      AuthAccountType.business => 'business',
      AuthAccountType.organization => 'organization',
    };
  }
}

class AuthUiState {
  final AuthScreenMode screenMode;
  final AuthRequestStatus requestStatus;
  final String? userId;
  final String? email;
  final bool isLoginPasswordVisible;
  final bool isSignupPasswordVisible;
  final bool isSignupConfirmPasswordVisible;
  final bool acceptsTerms;
  final AuthAccountType accountType;
  final String? errorMessage;
  final String? infoMessage;

  const AuthUiState({
    this.screenMode = AuthScreenMode.login,
    this.requestStatus = AuthRequestStatus.idle,
    this.userId,
    this.email,
    this.isLoginPasswordVisible = false,
    this.isSignupPasswordVisible = false,
    this.isSignupConfirmPasswordVisible = false,
    this.acceptsTerms = true,
    this.accountType = AuthAccountType.personal,
    this.errorMessage,
    this.infoMessage,
  });

  factory AuthUiState.fromSession(Session? session) {
    return AuthUiState(userId: session?.user.id, email: session?.user.email);
  }

  bool get isAuthenticated => userId != null;

  bool get isLoading => requestStatus == AuthRequestStatus.loading;

  AuthUiState copyWith({
    AuthScreenMode? screenMode,
    AuthRequestStatus? requestStatus,
    String? userId,
    String? email,
    bool clearAuthUser = false,
    bool? isLoginPasswordVisible,
    bool? isSignupPasswordVisible,
    bool? isSignupConfirmPasswordVisible,
    bool? acceptsTerms,
    AuthAccountType? accountType,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? infoMessage,
    bool clearInfoMessage = false,
  }) {
    return AuthUiState(
      screenMode: screenMode ?? this.screenMode,
      requestStatus: requestStatus ?? this.requestStatus,
      userId: clearAuthUser ? null : userId ?? this.userId,
      email: clearAuthUser ? null : email ?? this.email,
      isLoginPasswordVisible:
          isLoginPasswordVisible ?? this.isLoginPasswordVisible,
      isSignupPasswordVisible:
          isSignupPasswordVisible ?? this.isSignupPasswordVisible,
      isSignupConfirmPasswordVisible:
          isSignupConfirmPasswordVisible ?? this.isSignupConfirmPasswordVisible,
      acceptsTerms: acceptsTerms ?? this.acceptsTerms,
      accountType: accountType ?? this.accountType,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
    );
  }
}

class AuthUiNotifier extends StateNotifier<AuthUiState> {
  final AuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;

  AuthUiNotifier(this._authService)
    : super(AuthUiState.fromSession(_authService.currentSession)) {
    _authSubscription = _authService.authStateChanges.listen(
      (authState) {
        final session = authState.session;
        state = state.copyWith(
          userId: session?.user.id,
          email: session?.user.email,
          clearAuthUser: session == null,
          requestStatus: AuthRequestStatus.idle,
          clearErrorMessage: true,
        );
      },
      onError: (_, _) {
        state = state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          errorMessage: 'Session refresh failed. Please sign in again.',
        );
      },
    );
  }

  void showLogin() {
    state = state.copyWith(
      screenMode: AuthScreenMode.login,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
  }

  void showSignup() {
    state = state.copyWith(
      screenMode: AuthScreenMode.signup,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
  }

  void toggleLoginPasswordVisibility() {
    state = state.copyWith(
      isLoginPasswordVisible: !state.isLoginPasswordVisible,
    );
  }

  void toggleSignupPasswordVisibility() {
    state = state.copyWith(
      isSignupPasswordVisible: !state.isSignupPasswordVisible,
    );
  }

  void toggleSignupConfirmPasswordVisibility() {
    state = state.copyWith(
      isSignupConfirmPasswordVisible: !state.isSignupConfirmPasswordVisible,
    );
  }

  void toggleAcceptsTerms() {
    state = state.copyWith(acceptsTerms: !state.acceptsTerms);
  }

  void selectAccountType(AuthAccountType value) {
    state = state.copyWith(accountType: value);
  }

  void showValidationError(String message) {
    state = state.copyWith(
      requestStatus: AuthRequestStatus.failure,
      errorMessage: message,
      clearInfoMessage: true,
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _runAuthRequest(() async {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      final user = response.session?.user ?? response.user;

      state = state.copyWith(
        userId: user?.id,
        email: user?.email,
        clearAuthUser: user == null,
        requestStatus: AuthRequestStatus.success,
        clearErrorMessage: true,
        clearInfoMessage: true,
      );
    });
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _runAuthRequest(() async {
      final response = await _authService.signUpWithEmail(
        fullName: fullName,
        email: email,
        password: password,
        accountType: state.accountType.label,
      );

      final user = response.session?.user;
      final hasSession = user != null;
      state = state.copyWith(
        userId: user?.id,
        email: user?.email,
        clearAuthUser: !hasSession,
        requestStatus: AuthRequestStatus.success,
        screenMode: hasSession ? state.screenMode : AuthScreenMode.login,
        infoMessage: hasSession
            ? null
            : 'Check your email to confirm your account before signing in.',
        clearErrorMessage: true,
        clearInfoMessage: hasSession,
      );
    });
  }

  Future<void> signOut() async {
    await _runAuthRequest(() async {
      await _authService.signOut();
      state = state.copyWith(
        clearAuthUser: true,
        screenMode: AuthScreenMode.login,
        requestStatus: AuthRequestStatus.idle,
        clearErrorMessage: true,
        clearInfoMessage: true,
      );
    });
  }

  Future<void> _runAuthRequest(Future<void> Function() request) async {
    state = state.copyWith(
      requestStatus: AuthRequestStatus.loading,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );

    try {
      await request();
    } on AuthException catch (error) {
      state = state.copyWith(
        requestStatus: AuthRequestStatus.failure,
        errorMessage: _safeAuthMessage(error.message),
      );
    } on AuthServiceException catch (error) {
      state = state.copyWith(
        requestStatus: AuthRequestStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        requestStatus: AuthRequestStatus.failure,
        errorMessage: 'Authentication failed. Please try again.',
      );
    }
  }

  String _safeAuthMessage(String message) {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      return 'Authentication failed. Please try again.';
    }

    return cleanMessage;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => const AuthService());

final authUiProvider = StateNotifierProvider<AuthUiNotifier, AuthUiState>(
  (ref) => AuthUiNotifier(ref.watch(authServiceProvider)),
);
