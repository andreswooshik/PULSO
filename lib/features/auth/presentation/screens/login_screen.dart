import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
            email: _emailController.text,
            password: _passwordController.text,
          );
    } finally {
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authUiProvider);
    final authNotifier = ref.read(authUiProvider.notifier);

    return AuthPage(
      children: [
        const AuthBrandHeader(
          title: 'Welcome back',
          subtitle:
              'Stay connected with your community updates, profile, and activity.',
        ),
        const SizedBox(height: 34),
        const AuthSectionTitle(
          title: 'Sign in',
          subtitle: 'Use your PULSO account to continue.',
        ),
        if (authState.errorMessage != null) ...[
          const SizedBox(height: 16),
          AuthMessageBanner(message: authState.errorMessage!, isError: true),
        ],
        if (authState.infoMessage != null) ...[
          const SizedBox(height: 16),
          AuthMessageBanner(message: authState.infoMessage!),
        ],
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                controller: _emailController,
                label: 'Email address',
                hintText: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                obscureText: !authState.isLoginPasswordVisible,
                trailingIcon: authState.isLoginPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onTrailingPressed: authNotifier.toggleLoginPasswordVisibility,
                validator: _validatePassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot password?',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryAction(
          label: 'Sign in',
          isLoading: authState.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        const AuthDividerLabel(),
        const SizedBox(height: 18),
        const AuthSocialButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Continue with Google',
        ),
        const SizedBox(height: 12),
        const AuthSocialButton(
          icon: Icons.facebook_rounded,
          label: 'Continue with Facebook',
        ),
        const SizedBox(height: 28),
        AuthFooterPrompt(
          text: 'New to PULSO? ',
          actionText: 'Create an account',
          onActionPressed: authNotifier.showSignup,
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
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
