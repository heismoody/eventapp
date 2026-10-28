import 'package:flutter/services.dart' show appFlavor;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';

/// Which build this is, decided at build time by `--flavor dev|prod`.
///
/// prod is the Google Play build: locked to the production server, and
/// updated only through the Play Store. dev is self-hosted on appdev with
/// its own in-app updater, and keeps the "Advanced" server override for
/// pointing at a laptop while testing.
/// A build with no flavor (iOS/macOS, or a plain `flutter run` on a
/// platform without flavors) is treated as dev, so a production install can
/// never end up there by accident.
class AppEnvironment {
  AppEnvironment._();

  static bool get isProd => appFlavor == 'prod';

  static String get label => isProd ? 'Production' : 'Development';

  static String get defaultBaseUrl =>
      isProd ? 'https://app.cardly.co.tz' : 'https://appdev.cardly.co.tz';

  static bool get allowsServerOverride => !isProd;

  /// Only the self-hosted dev build updates itself. Google Play forbids an
  /// app it distributes from downloading and installing its own APK, so
  /// the prod (Play) build leaves updates entirely to the Play Store.
  static bool get hasSelfUpdates => !isProd;

  /// The dev build's self-hosted update manifest on appdev, served from the
  /// portal's public/app-releases (no auth — it's checked before anyone has
  /// to be logged in).
  static const String releaseManifestPath = '/app-releases/latest-dev.json';

  /// The server every request goes to. In prod any previously saved
  /// override is ignored — an install that was once pointed elsewhere still
  /// talks to production (and only gets production updates).
  static String baseUrl(SharedPreferences prefs) {
    if (!allowsServerOverride) return defaultBaseUrl;
    final saved = prefs.getString(ApiConfig.baseUrlKey)?.trim();
    return (saved == null || saved.isEmpty) ? defaultBaseUrl : saved;
  }
}
