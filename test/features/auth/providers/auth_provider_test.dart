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
    test('passes identifier to auth service', () async {
      final notifier = AuthUiNotifier(authService);
      final response = AuthResponse(user: _testUser());

      when(
        () => authService.signInWithEmailOrUsername(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      await notifier.signIn(
        identifier: 'user@example.com',
        password: 'securePassword123',
      );

      expect(notifier.state.requestStatus, AuthRequestStatus.success);
      verify(
        () => authService.signInWithEmailOrUsername(
          identifier: 'user@example.com',
          password: 'securePassword123',
        ),
      ).called(1);
    });
  });

  group('AuthUiNotifier screen changes', () {
    test('clears stale messages when opening signup', () {
      final notifier = AuthUiNotifier(authService);

      notifier.showValidationError('Could not resolve username.');
      notifier.showSignup();

      expect(notifier.state.screenMode, AuthScreenMode.signup);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.infoMessage, isNull);
    });
  });

  group('AuthUiNotifier signup username availability', () {
    test('shows an error when username is already taken', () async {
      final notifier = AuthUiNotifier(authService);

      when(
        () => authService.isUsernameAvailable('taken_user'),
      ).thenAnswer((_) async => false);

      await notifier.signUp(
        firstName: 'Juan',
        middleInitial: 'D',
        lastName: 'Dela Cruz',
        suffix: 'Jr.',
        gender: 'Male',
        birthday: '2000-01-31',
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
          firstName: any(named: 'firstName'),
          middleInitial: any(named: 'middleInitial'),
          lastName: any(named: 'lastName'),
          suffix: any(named: 'suffix'),
          gender: any(named: 'gender'),
          birthday: any(named: 'birthday'),
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
          firstName: any(named: 'firstName'),
          middleInitial: any(named: 'middleInitial'),
          lastName: any(named: 'lastName'),
          suffix: any(named: 'suffix'),
          gender: any(named: 'gender'),
          birthday: any(named: 'birthday'),
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          accountType: any(named: 'accountType'),
        ),
      ).thenAnswer((_) async => response);

      await notifier.signUp(
        firstName: 'Juan',
        middleInitial: 'D',
        lastName: 'Dela Cruz',
        suffix: 'Jr.',
        gender: 'Male',
        birthday: '2000-01-31',
        username: 'new_user',
        email: 'juan@example.com',
        password: 'securePassword123',
      );

      expect(notifier.state.requestStatus, AuthRequestStatus.success);
      verify(() => authService.isUsernameAvailable('new_user')).called(1);
      verify(
        () => authService.signUpWithEmail(
          firstName: 'Juan',
          middleInitial: 'D',
          lastName: 'Dela Cruz',
          suffix: 'Jr.',
          gender: 'Male',
          birthday: '2000-01-31',
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
