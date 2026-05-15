import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/core/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                style: TextStyle(color: AppTheme.pearl.withValues(alpha: 0.78)),
              ),
            ),
            const SizedBox(height: 42),
            const AppTextField(
              label: 'Username or Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            TextFormField(
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
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
                onPressed: () {},
                child: const Text(
                  'Log In',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () {}, child: const Text('Forgot password?')),
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
