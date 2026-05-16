import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    try {
      await ref
          .read(authUiProvider.notifier)
          .signIn(
            identifier: _identifierController.text,
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      if (ref.read(authUiProvider).isAuthenticated) {
        context.go(AppRoutes.feed);
      }
    } finally {
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authUiProvider);
    final authNotifier = ref.read(authUiProvider.notifier);

    return PopScope(
      canPop: false,
      child: AuthPage(
        compactTopPadding: 52,
        regularTopPadding: 68,
        children: [
          const Center(
            child: Text(
              'Pulso',
              style: TextStyle(
                color: AppTheme.midnight,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Feel the heartbeat of your community',
              style: TextStyle(
                color: AppTheme.midnight.withValues(alpha: 0.72),
              ),
            ),
          ),
          if (authState.errorMessage != null) ...[
            const SizedBox(height: 24),
            AuthMessageBanner(message: authState.errorMessage!, isError: true),
          ],
          if (authState.infoMessage != null) ...[
            const SizedBox(height: 24),
            AuthMessageBanner(message: authState.infoMessage!),
          ],
          const SizedBox(height: 42),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthInputField(
                  controller: _identifierController,
                  label: 'Username or email',
                  hintText: 'juan_delacruz or you@example.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: _validateIdentifier,
                ),
                const SizedBox(height: 14),
                AuthInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !authState.isLoginPasswordVisible,
                  trailingIcon: authState.isLoginPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onTrailingPressed: authNotifier.toggleLoginPasswordVisibility,
                  validator: _validatePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AuthPrimaryAction(
            label: 'Log In',
            isLoading: authState.isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
          TextButton(onPressed: () {}, child: const Text('Forgot password?')),
          const SizedBox(height: 10),
          const AuthDividerLabel(),
          const SizedBox(height: 20),
          AuthSocialButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          AuthSocialButton(
            icon: Icons.facebook,
            label: 'Continue with Facebook',
            onPressed: () {},
          ),
          const SizedBox(height: 28),
          AuthFooterPrompt(
            text: "Don't have an account? ",
            actionText: 'Sign Up',
            onActionPressed: () => context.push(AppRoutes.signup),
          ),
        ],
      ),
    );
  }

  String? _validateIdentifier(String? value) {
    final identifier = value?.trim() ?? '';

    if (identifier.isEmpty) {
      return 'Username or email is required.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Password is required.';
    }

    return null;
  }
}
