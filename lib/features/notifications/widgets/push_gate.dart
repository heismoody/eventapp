import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale_provider.dart';
import '../../../app/router.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../../event_request/services/my_request_store.dart';
import '../../update/services/update_service.dart';
import '../../update/widgets/update_sheet.dart';
import '../services/push_service.dart';

/// Wires push notifications into the app:
/// - keeps the portal up to date with this phone's token, who is signed in,
///   the request sent from it and the language;
/// - asks for permission once, the first time the app opens;
/// - puts a notification that arrives while the app is open into the
///   notification shade, like one that arrives while it's closed;
/// - opens the right screen when a notification is tapped, or checks for
///   an app update when it's the "new version is out" one (the update
///   sheet, or a message saying it's already the latest or the check
///   failed).
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
  /// Not a screen: it checks for the update there and then.
  static const _appUpdateRoute = '/app-update';
  bool _checkingUpdate = false;

  void _go(String route) {
    if (route == _appUpdateRoute) {
      _checkForUpdate();
      return;
    }
    if (!route.startsWith('/')) return;
    ref.read(routerProvider).go(route);
  }

  /// Opens the update sheet, signed in or not, or says why it didn't:
  /// already up to date, or the check failed. A tap never does nothing.
  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    _checkingUpdate = true;
    try {
      final release = await ref.read(updateServiceProvider).checkNow();
      if (!mounted) return;
      final navigator = ref
          .read(routerProvider)
          .routerDelegate
          .navigatorKey
          .currentContext;
      if (release == null) {
        AppToast.success(appL10n.updateAlreadyLatest);
      } else if (navigator != null && navigator.mounted) {
        await showUpdateSheet(navigator, release);
      }
    } catch (error) {
      debugPrint('[push] update check failed: $error');
      AppToast.error(appL10n.updateCheckFailed);
    } finally {
      _checkingUpdate = false;
    }
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
