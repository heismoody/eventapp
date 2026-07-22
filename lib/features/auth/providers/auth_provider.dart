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
    await ref
        .read(eventSelectionControllerProvider)
        .initializeOwnedEvent(user!.ownedEventId!);
  }

  return true;
});

bool isAuthenticated(String? token) {
  return token != null && token.isNotEmpty && !JwtUtils.isExpired(token);
}
