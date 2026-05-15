import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/features/auth/presentation/screens/authenticated_screen.dart';
import 'package:pulso/features/auth/presentation/screens/login_screen.dart';
import 'package:pulso/features/auth/presentation/screens/signup_screen.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';

class AuthFlowScreen extends ConsumerWidget {
  const AuthFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUiProvider);

    if (authState.isAuthenticated) {
      return const AuthenticatedScreen();
    }

    return switch (authState.screenMode) {
      AuthScreenMode.login => const LoginScreen(),
      AuthScreenMode.signup => const SignupScreen(),
    };
  }
}
