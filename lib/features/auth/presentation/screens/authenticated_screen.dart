import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';

class AuthenticatedScreen extends ConsumerWidget {
  const AuthenticatedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUiProvider);
    final authNotifier = ref.read(authUiProvider.notifier);
    final email = authState.session?.user.email ?? 'Signed-in user';

    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrandHeader(
                    title: 'You are signed in',
                    subtitle:
                        'Your Supabase session is active and persisted by the client.',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AuthColors.border),
                    ),
                    child: Text(
                      email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AuthColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryAction(
                    label: 'Log out',
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading
                        ? null
                        : authNotifier.signOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
