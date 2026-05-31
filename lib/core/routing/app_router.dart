import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/routing/app_shell.dart';
import 'package:pulso/features/activity/presentation/screens/activity_screen.dart';
import 'package:pulso/features/auth/presentation/screens/login_screen.dart';
import 'package:pulso/features/auth/presentation/screens/signup_screen.dart';
import 'package:pulso/features/feed/presentation/screens/feed_screen.dart';
import 'package:pulso/features/posts/presentation/screens/create_post_screen.dart';
import 'package:pulso/features/profile/presentation/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

GoRouter createAppRouter() {
  final routerRefreshNotifier = _RouterRefreshNotifier();

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: routerRefreshNotifier,
    redirect: (context, state) {
      final isAuthenticated = _hasActiveSession();
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.feed;
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.feed,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FeedScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.createPost,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CreatePostScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.activity,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ActivityScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
    ],
  );
}

bool _hasActiveSession() {
  try {
    return Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    return false;
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier() {
    try {
      _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
        _,
      ) {
        notifyListeners();
      });
    } catch (_) {
      _subscription = null;
    }
  }

  StreamSubscription<AuthState>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
