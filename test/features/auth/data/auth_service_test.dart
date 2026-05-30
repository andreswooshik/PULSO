import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulso/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

dynamic _fallbackOnValue(dynamic value) => value;

void main() {
  late MockSupabaseClient supabaseClient;
  late MockGoTrueClient authClient;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(_fallbackOnValue);
  });

  setUp(() {
    supabaseClient = MockSupabaseClient();
    authClient = MockGoTrueClient();
    authService = AuthService(client: supabaseClient);

    when(() => supabaseClient.auth).thenReturn(authClient);
  });

  group('AuthService', () {
    test(
      'signInWithEmailOrUsername delegates to Supabase auth with trimmed identifier',
      () async {
        final user = _testUser();
        final response = AuthResponse(user: user);

        when(
          () => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => response);

        final result = await authService.signInWithEmailOrUsername(
          identifier: ' user@example.com ',
          password: 'securePassword123',
        );

        expect(result.user, user);
        verify(
          () => authClient.signInWithPassword(
            email: 'user@example.com',
            password: 'securePassword123',
          ),
        ).called(1);
      },
    );

    test(
      'signInWithEmailOrUsername resolves normalized username before login',
      () async {
        final user = _testUser();
        final response = AuthResponse(user: user);
        final usernameLookup = MockPostgrestFilterBuilder();

        when(
          () => supabaseClient.rpc(
            'get_email_by_username',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => usernameLookup);
        when(
          () => usernameLookup.then<dynamic>(
            any<FutureOr<dynamic> Function(dynamic)>(),
            onError: any(named: 'onError'),
          ),
        ).thenAnswer((invocation) async {
          final onValue =
              invocation.positionalArguments.first
                  as FutureOr<dynamic> Function(dynamic);
          return onValue('juan@example.com');
        });
        when(
          () => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => response);

        final result = await authService.signInWithEmailOrUsername(
          identifier: ' Juan_DelaCruz ',
          password: 'securePassword123',
        );

        expect(result.user, user);
        verify(
          () => supabaseClient.rpc(
            'get_email_by_username',
            params: {'requested_username': 'juan_delacruz'},
          ),
        ).called(1);
        verify(
          () => authClient.signInWithPassword(
            email: 'juan@example.com',
            password: 'securePassword123',
          ),
        ).called(1);
      },
    );

    test('signUpWithEmail delegates user metadata safely', () async {
      final user = _testUser();
      final response = AuthResponse(user: user);

      when(
        () => authClient.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final result = await authService.signUpWithEmail(
        firstName: ' Juan ',
        middleInitial: ' d ',
        lastName: ' Dela Cruz ',
        suffix: ' Jr. ',
        gender: 'Male',
        birthday: '2000-01-31',
        username: ' Juan_DelaCruz ',
        email: ' new@example.com ',
        password: 'securePassword123',
        accountType: 'personal',
      );

      expect(result.user, user);
      verify(
        () => authClient.signUp(
          email: 'new@example.com',
          password: 'securePassword123',
          data: {
            'first_name': 'Juan',
            'middle_initial': 'D',
            'last_name': 'Dela Cruz',
            'suffix': 'Jr.',
            'gender': 'Male',
            'birthday': '2000-01-31',
            'full_name': 'Juan D. Dela Cruz Jr.',
            'username': 'juan_delacruz',
            'account_type': 'personal',
          },
        ),
      ).called(1);
    });

    test('signOut delegates to Supabase auth', () async {
      when(() => authClient.signOut()).thenAnswer((_) async {});

      await authService.signOut();

      verify(() => authClient.signOut()).called(1);
    });

    test('currentSession returns Supabase current session', () {
      final session = _testSession();
      when(() => authClient.currentSession).thenReturn(session);

      expect(authService.currentSession, session);
    });

    test('authStateChanges returns Supabase auth stream', () {
      final stream = Stream<AuthState>.empty();
      when(() => authClient.onAuthStateChange).thenAnswer((_) => stream);

      expect(authService.authStateChanges, stream);
    });
  });
}

User _testUser() {
  return const User(
    id: 'user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    email: 'user@example.com',
    createdAt: '2026-05-15T00:00:00Z',
  );
}

Session _testSession() {
  return Session(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: _testUser(),
  );
}
