import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/events/screens/event_picker_screen.dart';
import '../features/shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authTokenProvider);
  ref.watch(authInitializedProvider);
  ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final token = ref.read(authTokenProvider);
      final authenticated = isAuthenticated(token);
      final user = ref.read(currentUserProvider);

      if (!authenticated && !isLoggingIn) return '/login';

      if (authenticated && isLoggingIn) {
        return user?.isEventScoped == true ? '/shell/dashboard' : '/events';
      }

      if (authenticated &&
          user?.isEventScoped == true &&
          state.matchedLocation == '/events') {
        return '/shell/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final skipSplash = state.uri.queryParameters['skip'] == '1';
          return WelcomeScreen(skipSplash: skipSplash);
        },
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventPickerScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/shell/dashboard',
            builder: (context, state) => const DashboardTab(),
          ),
          GoRoute(
            path: '/shell/scanner',
            builder: (context, state) => const ScannerTab(),
          ),
          GoRoute(
            path: '/shell/attendees',
            builder: (context, state) => const AttendeesTab(),
          ),
          GoRoute(
            path: '/shell/team',
            builder: (context, state) => const TeamTab(),
          ),
          GoRoute(
            path: '/shell/settings',
            builder: (context, state) => const SettingsTab(),
          ),
        ],
      ),
    ],
  );
});
