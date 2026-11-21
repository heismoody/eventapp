import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale_provider.dart';
import '../../../app/router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../event_request/services/my_request_store.dart';
import '../../update/services/update_service.dart';
import '../services/push_service.dart';

/// Wires push notifications into the app:
/// - keeps the portal up to date with this phone's token, who is signed in,
///   the request sent from it and the language;
/// - asks for permission once, the first time the app opens;
/// - puts a notification that arrives while the app is open into the
///   notification shade, like one that arrives while it's closed;
/// - opens the right screen when a notification is tapped, or checks for
///   an app update when it's the "new version is out" one.
class PushGate extends ConsumerStatefulWidget {
  const PushGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushGate> createState() => _PushGateState();
}

class _PushGateState extends ConsumerState<PushGate> {
  final _subs = <StreamSubscription<dynamic>>[];

  /// LocalNotifications.kt: shows notifications while the app is open.
  static const _notify = MethodChannel('cardly/notify');

  PushService get _push => ref.read(pushServiceProvider);

  @override
  void initState() {
    super.initState();
    final messaging = FirebaseMessaging.instance;
    // See PushService.currentToken about the deprecation.
    // ignore: deprecated_member_use
    _subs.add(messaging.onTokenRefresh.listen((t) => _push.register(token: t)));
    _subs.add(FirebaseMessaging.onMessage.listen(_showInApp));
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
    _notify.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) {
        _go(call.arguments as String);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ask once, the first time the app opens.
      _askThenRegister();
      // Opened by tapping a notification while the app was closed.
      final initial = await messaging.getInitialMessage();
      if (initial != null && mounted) _open(initial);
      // Opened by tapping one we showed while the app was open.
      try {
        final route = await _notify.invokeMethod<String>('takeLaunchRoute');
        if (route != null && mounted) _go(route);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _notify.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _showInApp(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    try {
      await _notify.invokeMethod<void>('show', {
        'title': n.title ?? '',
        'body': n.body ?? '',
        'route': message.data['route'],
      });
    } catch (error) {
      debugPrint('[push] show failed: $error');
    }
  }

  void _open(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String) _go(route);
  }

  /// The portal's "new version is out" notification (lib/push-release.ts).
  /// Not a screen: it checks for the update again, so the shell shows the
  /// update dialog even when the app had already checked before it arrived.
  static const _appUpdateRoute = '/app-update';

  void _go(String route) {
    if (route == _appUpdateRoute) {
      ref.invalidate(appUpdateProvider);
      return;
    }
    if (!route.startsWith('/')) return;
    ref.read(routerProvider).go(route);
  }

  Future<void> _askThenRegister() async {
    await _push.askOnce();
    await _push.register();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (previous, next) {
      if (next != null && previous?.id != next.id) {
        _askThenRegister();
      } else if (next == null && previous != null) {
        _push.forgetAccount();
      }
    });
    ref.listen(myRequestProvider, (previous, next) {
      if (next != null && previous?.id != next.id) {
        _askThenRegister();
      } else if (next == null && previous != null) {
        _push.register();
      }
    });
    ref.listen(localeProvider, (_, _) => _push.register());
    return widget.child;
  }
}
