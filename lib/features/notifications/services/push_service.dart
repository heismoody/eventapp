import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale_provider.dart';
import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../event_request/services/my_request_store.dart';

final pushServiceProvider = Provider<PushService>(PushService.new);

/// Push notifications through Firebase Cloud Messaging.
///
/// The phone tells the portal its token (`/api/mobile/devices`), linked to
/// whoever is signed in and to the event request sent from it, so the
/// portal knows where to send. Nothing here ever throws: notifications are
/// a bonus, never a reason for a screen to fail.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  static const _askedKey = 'push_permission_asked';

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// The classic FCM registration token, which the portal sends to with
  /// FCM HTTP v1 (`message.token`). firebase_messaging 17 deprecates it in
  /// favour of installation IDs (register / onRegistered). Move both sides
  /// together once the portal can target those.
  // ignore: deprecated_member_use
  Future<String?> currentToken() => _messaging.getToken();

  String get _base =>
      AppEnvironment.baseUrl(_ref.read(sharedPreferencesProvider));

  Dio get _dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<bool> get allowed async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Asks for permission once per install, the first time the app opens.
  /// Android 12 and older allow notifications without asking.
  Future<void> askOnce() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_askedKey) == true) return;
    await prefs.setBool(_askedKey, true);
    try {
      await _messaging.requestPermission();
    } catch (error) {
      debugPrint('[push] permission request failed: $error');
    }
  }

  /// Tells the portal this phone's token, who is signed in and which
  /// request it sent. Safe to call often: the portal just updates the row.
  Future<void> register({String? token}) async {
    try {
      if (!await allowed) return;
      final fcmToken = token ?? await currentToken();
      if (fcmToken == null) return;
      if (!AppEnvironment.isProd) debugPrint('[push] token: $fcmToken');

      final bearer = await _ref.read(authServiceProvider).getToken();
      final locale =
          _ref.read(localeProvider)?.languageCode ?? appL10n.localeName;
      await _dio.post(
        '$_base${ApiConfig.devicesPath}',
        data: {
          'token': fcmToken,
          'platform': 'android',
          'flavor': AppEnvironment.isProd ? 'prod' : 'dev',
          'locale': locale == 'sw' ? 'sw' : 'en',
          'eventRequestId': _ref.read(myRequestProvider)?.id,
        },
        options: Options(
          headers: isAuthenticated(bearer)
              ? {'Authorization': 'Bearer $bearer'}
              : null,
        ),
      );
    } catch (error) {
      debugPrint('[push] register failed: $error');
    }
  }

  /// After signing out: the phone stops getting that account's news.
  Future<void> forgetAccount() async {
    try {
      final fcmToken = await currentToken();
      if (fcmToken == null) return;
      await _dio.delete(
        '$_base${ApiConfig.devicesPath}',
        data: {'token': fcmToken},
      );
    } catch (error) {
      debugPrint('[push] sign-out update failed: $error');
    }
  }
}
