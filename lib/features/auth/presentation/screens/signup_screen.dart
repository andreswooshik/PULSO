import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/constants/app_constants.dart';
import 'package:pulso/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authNotifier = ref.read(authUiProvider.notifier);
    final authState = ref.read(authUiProvider);
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (!authState.acceptsTerms) {
      authNotifier.showValidationError(
        'You need to accept the Terms and Privacy Policy.',
      );
      return;
    }

    try {
      await authNotifier.signUp(
        fullName: _nameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } finally {
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authUiProvider);
    final authNotifier = ref.read(authUiProvider.notifier);

    return AuthPage(
      compactTopPadding: 24,
      regularTopPadding: 36,
      children: [
        const AuthBrandHeader(
          title: 'Join PULSO',
          subtitle:
              'Create a profile for community updates, events, and local support.',
        ),
        const SizedBox(height: 28),
        const AuthSectionTitle(
          title: 'Create your account',
          subtitle: 'Join PULSO and start connecting with your community.',
        ),
        if (authState.errorMessage != null) ...[
          const SizedBox(height: 16),
          AuthMessageBanner(message: authState.errorMessage!, isError: true),
        ],
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                controller: _nameController,
                label: 'Full name',
                hintText: 'Juan Dela Cruz',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _usernameController,
                label: 'Username',
                hintText: 'juan_delacruz',
                icon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  final normalized = value.trim().toLowerCase();
                  if (value != normalized) {
                    _usernameController.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
                    );
                  }
                },
                validator: _validateUsername,
              ),
              const SizedBox(height: 16),
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
                hintText: 'Create a password',
                icon: Icons.lock_outline_rounded,
                obscureText: !authState.isSignupPasswordVisible,
                trailingIcon: authState.isSignupPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                textInputAction: TextInputAction.next,
                onTrailingPressed: authNotifier.toggleSignupPasswordVisibility,
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hintText: 'Re-enter your password',
                icon: Icons.verified_user_outlined,
                obscureText: !authState.isSignupConfirmPasswordVisible,
                trailingIcon: authState.isSignupConfirmPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onTrailingPressed:
                    authNotifier.toggleSignupConfirmPasswordVisibility,
                validator: _validateConfirmPassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Account type',
          style: textTheme.labelLarge?.copyWith(
            color: AuthColors.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AuthTypePill(
              label: 'Personal',
              icon: Icons.person_outline_rounded,
              selected: authState.accountType == AuthAccountType.personal,
              onPressed: () {
                authNotifier.selectAccountType(AuthAccountType.personal);
              },
            ),
            AuthTypePill(
              label: 'Business',
              icon: Icons.business_center_outlined,
              selected: authState.accountType == AuthAccountType.business,
              onPressed: () {
                authNotifier.selectAccountType(AuthAccountType.business);
              },
            ),
            AuthTypePill(
              label: 'Organization',
              icon: Icons.apartment_outlined,
              selected: authState.accountType == AuthAccountType.organization,
              onPressed: () {
                authNotifier.selectAccountType(AuthAccountType.organization);
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthCheckmark(
              checked: authState.acceptsTerms,
              margin: const EdgeInsets.only(top: 1),
              onPressed: authNotifier.toggleAcceptsTerms,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  children: [
                    TextSpan(
                      text: 'Terms',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: AuthColors.body,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AuthPrimaryAction(
          label: 'Create account',
          isLoading: authState.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: 28),
        AuthFooterPrompt(
          text: 'Already have an account? ',
          actionText: 'Sign in',
          onActionPressed: authNotifier.showLogin,
        ),
      ],
    );
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Full name is required.';
    }

    if (name.length > AppConstants.maxNameLength) {
      return 'Name must be ${AppConstants.maxNameLength} characters or less.';
    }

    return null;
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

  String? _validateUsername(String? value) {
    final username = value?.trim().toLowerCase() ?? '';
    final usernamePattern = RegExp(r'^[a-z0-9_]+$');

    if (username.isEmpty) {
      return 'Username is required.';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters.';
    }

    if (username.length > 24) {
      return 'Username must be 24 characters or less.';
    }

    if (!usernamePattern.hasMatch(username)) {
      return 'Use only lowercase letters, numbers, and underscores.';
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) {
      return 'Confirm your password.';
    }

    if (confirmPassword != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }
}
