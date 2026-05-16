import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/routing/app_shell.dart';
import 'package:pulso/features/activity/presentation/screens/activity_screen.dart';
import 'package:pulso/features/auth/presentation/screens/login_screen.dart';
import 'package:pulso/features/auth/presentation/screens/signup_screen.dart';
import 'package:pulso/features/feed/presentation/screens/feed_screen.dart';
import 'package:pulso/features/posts/presentation/screens/create_post_screen.dart';
import 'package:pulso/features/profile/presentation/screens/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.feed,
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
