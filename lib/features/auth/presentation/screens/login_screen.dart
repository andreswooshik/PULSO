import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/core/widgets/widgets.dart';
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
    } finally {
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authUiProvider);
    final authNotifier = ref.read(authUiProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.go(AppRoutes.feed),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  'Pulso',
                  style: TextStyle(
                    color: AppTheme.sampaguita,
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
                    color: AppTheme.pearl.withValues(alpha: 0.78),
                  ),
                ),
              ),
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 24),
                _AuthMessage(message: authState.errorMessage!, isError: true),
              ],
              if (authState.infoMessage != null) ...[
                const SizedBox(height: 24),
                _AuthMessage(message: authState.infoMessage!),
              ],
              const SizedBox(height: 42),
              AppTextField(
                controller: _identifierController,
                label: 'Username or email',
                hint: 'juan_delacruz or you@example.com',
                keyboardType: TextInputType.text,
                validator: _validateIdentifier,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: !authState.isLoginPasswordVisible,
                validator: _validatePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: authState.isLoginPasswordVisible
                        ? 'Hide password'
                        : 'Show password',
                    onPressed: authNotifier.toggleLoginPasswordVisibility,
                    icon: Icon(
                      authState.isLoginPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [AppTheme.coral, AppTheme.royalBlue],
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Log In',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {},
                child: const Text('Forgot password?'),
              ),
              const SizedBox(height: 10),
              const _DividerLabel(label: 'OR'),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.facebook),
                label: const Text('Continue with Facebook'),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.signup),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _AuthMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _AuthMessage({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.pearl.withValues(alpha: 0.24))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label, style: const TextStyle(color: Color(0xFF9FB3D9))),
        ),
        Expanded(child: Divider(color: AppTheme.pearl.withValues(alpha: 0.24))),
      ],
    );
  }
}
