import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/main.dart';

void main() {
  testWidgets('App starts on the login screen for signed-out users', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Pulso'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Feed'), findsNothing);
  });

  testWidgets('Login screen can navigate to sign up', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Account type'), findsOneWidget);
  });
}
