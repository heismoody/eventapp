import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/events/screens/event_picker_screen.dart';
import '../features/shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authTokenProvider);
  final authState = ref.watch(authInitializedProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isReady = authState.maybeWhen(data: (v) => v, orElse: () => false);

      if (!isReady && !isLoggingIn) return '/login';
      if (isReady && isLoggingIn) return '/events';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
            path: '/shell/sms',
            builder: (context, state) => const SmsLogsTab(),
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
