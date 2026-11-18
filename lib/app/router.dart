import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/widgets/login_form.dart';
import '../features/event_request/screens/first_password_screen.dart';
import '../features/event_request/screens/request_event_screen.dart';
import '../features/event_request/screens/request_sent_screen.dart';
import '../features/events/screens/event_picker_screen.dart';
import '../features/contributions/screens/contribution_categories_screen.dart';
import '../features/attendees/screens/guest_detail_screen.dart';
import '../features/reports/screens/report_screen.dart';
import '../features/scanner/screens/scanner_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/settings/screens/edit_profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // One router for the app's whole life. A sign-in or sign-out re-runs the
  // redirect through refreshListenable. Watching these providers instead
  // rebuilt the router mid-navigation, which tripped Riverpod's "provider
  // changed before it rebuilt" assertion right after signing in.
  final authChanged = ValueNotifier<int>(0);
  void bump() => authChanged.value++;
  ref.listen(authTokenProvider, (_, _) => bump());
  ref.listen(authInitializedProvider, (_, _) => bump());
  ref.listen(currentUserProvider, (_, _) => bump());
  ref.onDispose(authChanged.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authChanged,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      // Open to anyone: asking Cardly for an event needs no account.
      final isPlanningEvent = state.matchedLocation.startsWith('/plan-event');
      final isResetting = state.matchedLocation == '/forgot-password';
      final token = ref.read(authTokenProvider);
      final authenticated = isAuthenticated(token);
      final user = ref.read(currentUserProvider);

      if (!authenticated && !isLoggingIn && !isPlanningEvent && !isResetting) {
        return '/login';
      }

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
          return WelcomeScreen(
            skipSplash: skipSplash,
            prefill: state.extra is LoginPrefill
                ? state.extra as LoginPrefill
                : null,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            ForgotPasswordScreen(initialIdentifier: state.extra as String?),
      ),
      GoRoute(
        path: '/plan-event',
        builder: (context, state) => const RequestEventScreen(),
      ),
      GoRoute(
        path: '/plan-event/sent',
        builder: (context, state) => const RequestSentScreen(),
      ),
      // A new customer whose event is ready chooses their first password.
      GoRoute(
        path: '/plan-event/password',
        builder: (context, state) => const FirstPasswordScreen(),
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
            path: '/shell/contributions',
            builder: (context, state) => const ContributionsTab(),
          ),
          GoRoute(
            path: '/shell/settings',
            builder: (context, state) => const SettingsTab(),
          ),
          GoRoute(
            path: '/shell/contribution-categories',
            builder: (context, state) => const ContributionCategoriesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/shell/profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/shell/guests/:attendeeId',
        builder: (context, state) =>
            GuestDetailScreen(attendeeId: state.pathParameters['attendeeId']!),
      ),
      // Full screen, over the tabs, opened from the Scan tab.
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/shell/report',
        builder: (context, state) => const ReportScreen(),
      ),
    ],
  );
});
