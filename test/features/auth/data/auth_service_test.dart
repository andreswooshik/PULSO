import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulso/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient supabaseClient;
  late MockGoTrueClient authClient;
  late AuthService authService;

  setUp(() {
    supabaseClient = MockSupabaseClient();
    authClient = MockGoTrueClient();
    authService = AuthService(client: supabaseClient);

    when(() => supabaseClient.auth).thenReturn(authClient);
  });

  group('AuthService', () {
    test(
      'signInWithEmail delegates to Supabase auth with trimmed email',
      () async {
        final user = _testUser();
        final response = AuthResponse(user: user);

        when(
          () => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => response);

        final result = await authService.signInWithEmail(
          email: ' user@example.com ',
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
        fullName: ' Juan Dela Cruz ',
        email: ' new@example.com ',
        password: 'securePassword123',
        accountType: 'member',
      );

      expect(result.user, user);
      verify(
        () => authClient.signUp(
          email: 'new@example.com',
          password: 'securePassword123',
          data: {'full_name': 'Juan Dela Cruz', 'account_type': 'member'},
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
