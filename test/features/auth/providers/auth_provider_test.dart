import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulso/features/auth/data/auth_service.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService authService;

  setUp(() {
    authService = MockAuthService();

    when(() => authService.currentSession).thenReturn(null);
    when(
      () => authService.authStateChanges,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
  });

  group('AuthUiNotifier sign in', () {
    test('passes username or email identifier to auth service', () async {
      final notifier = AuthUiNotifier(authService);
      final response = AuthResponse(user: _testUser());

      when(
        () => authService.signInWithEmail(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      await notifier.signIn(
        identifier: 'juan_delacruz',
        password: 'securePassword123',
      );

      expect(notifier.state.requestStatus, AuthRequestStatus.success);
      verify(
        () => authService.signInWithEmail(
          identifier: 'juan_delacruz',
          password: 'securePassword123',
        ),
      ).called(1);
    });
  });

  group('AuthUiNotifier signup username availability', () {
    test('shows an error when username is already taken', () async {
      final notifier = AuthUiNotifier(authService);

      when(
        () => authService.isUsernameAvailable('taken_user'),
      ).thenAnswer((_) async => false);

      await notifier.signUp(
        fullName: 'Juan Dela Cruz',
        username: 'taken_user',
        email: 'juan@example.com',
        password: 'securePassword123',
      );

      expect(notifier.state.requestStatus, AuthRequestStatus.failure);
      expect(
        notifier.state.errorMessage,
        'Username is already taken. Choose another username.',
      );
      verifyNever(
        () => authService.signUpWithEmail(
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          accountType: any(named: 'accountType'),
        ),
      );
    });

    test('checks username before creating the account', () async {
      final notifier = AuthUiNotifier(authService);
      final response = AuthResponse(user: _testUser());

      when(
        () => authService.isUsernameAvailable('new_user'),
      ).thenAnswer((_) async => true);
      when(
        () => authService.signUpWithEmail(
          fullName: any(named: 'fullName'),
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          accountType: any(named: 'accountType'),
        ),
      ).thenAnswer((_) async => response);

      await notifier.signUp(
        fullName: 'Juan Dela Cruz',
        username: 'new_user',
        email: 'juan@example.com',
        password: 'securePassword123',
      );

      expect(notifier.state.requestStatus, AuthRequestStatus.success);
      verify(() => authService.isUsernameAvailable('new_user')).called(1);
      verify(
        () => authService.signUpWithEmail(
          fullName: 'Juan Dela Cruz',
          username: 'new_user',
          email: 'juan@example.com',
          password: 'securePassword123',
          accountType: 'personal',
        ),
      ).called(1);
    });
  });
}

User _testUser() {
  return const User(
    id: 'user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    email: 'juan@example.com',
    createdAt: '2026-05-15T00:00:00Z',
  );
}
