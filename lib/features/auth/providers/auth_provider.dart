import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/jwt_utils.dart';
import '../../events/providers/event_provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final ownedEventIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.ownedEventId;
});

final authInitializedProvider = FutureProvider<bool>((ref) async {
  final authService = ref.read(authServiceProvider);
  final token = await authService.getToken();

  if (token == null || token.isEmpty || JwtUtils.isExpired(token)) {
    if (token != null && token.isNotEmpty) {
      await ref.read(sessionManagerProvider).handleSessionExpired();
    }
    return false;
  }

  ref.read(authTokenProvider.notifier).state = token;
  final user = await authService.getStoredUser();
  ref.read(currentUserProvider.notifier).state = user;

  if (user?.isEventScoped == true) {
    final ownedEventId = user!.ownedEventId!;

    // Restore whatever was already selected last session first — instant,
    // no network needed — so the dashboard never waits on connectivity to
    // show the event it already knows about.
    final controller = ref.read(eventSelectionControllerProvider);
    await controller.loadActiveEventFromPrefs();

    // The cache is only valid if it belongs to *this* account. If a
    // different account logged in on this device before (and logout didn't
    // get a chance to clear it, or this is a stale leftover), the cached id
    // won't match this user's own event — never trust it in that case.
    if (ref.read(activeEventIdProvider) != ownedEventId) {
      try {
        await controller.initializeOwnedEvent(ownedEventId);
      } catch (_) {
        // Network failed and there's nothing trustworthy cached — the
        // dashboard's empty state will prompt once connectivity returns.
      }
    }
  }

  return true;
});

bool isAuthenticated(String? token) {
  return token != null && token.isNotEmpty && !JwtUtils.isExpired(token);
}

/// Makes a fresh sign-in live: the router and every screen see the new
/// token and user. Call after [AuthService.login] or a password reset.
Future<void> publishSession(WidgetRef ref, UserModel user) async {
  final token = await ref.read(authServiceProvider).getToken();
  ref.read(authTokenProvider.notifier).state = token;
  ref.read(currentUserProvider.notifier).state = user;
  ref.invalidate(authInitializedProvider);
}

/// Where a just-signed-in person lands: their own event's dashboard, or
/// the event list for staff who work across events.
Future<String> homeRouteAfterSignIn(WidgetRef ref, UserModel user) async {
  if (user.isEventScoped) {
    await ref
        .read(eventSelectionControllerProvider)
        .initializeOwnedEvent(user.ownedEventId!);
    return '/shell/dashboard';
  }
  return '/events';
}
