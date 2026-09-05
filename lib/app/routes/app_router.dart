import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gaweflutter/features/auth/login_screen.dart';
import 'package:gaweflutter/features/dashboard/dashboard_screen.dart';
import 'package:gaweflutter/features/server_config/presentation/screens/server_config_screen.dart';
import 'package:gaweflutter/features/splash/presentation/screens/splash_screen.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider.select((state) => state.status));
});

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStatusProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash' || loc == '/server-config') {
        return null; // Let splash and server-config handle transitions
      }

      final isLoggedIn = authStatus == AuthStatus.authenticated;
      final isLoggingIn = loc == '/login';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/server-config',
        builder: (context, state) {
          final isModal = state.uri.queryParameters['isModal'] == 'true';
          return ServerConfigScreen(isModal: isModal);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});

