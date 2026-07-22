import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'auth_service.dart';

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(ref);
});

class SessionManager {
  SessionManager(this._ref);

  final Ref _ref;
  bool _handlingExpiry = false;

  Future<void> handleSessionExpired() async {
    if (_handlingExpiry) return;
    _handlingExpiry = true;

    try {
      await _ref.read(authServiceProvider).logout();
      _ref.read(authTokenProvider.notifier).state = null;
      _ref.read(currentUserProvider.notifier).state = null;
      _ref.invalidate(authInitializedProvider);
    } finally {
      _handlingExpiry = false;
    }
  }
}
