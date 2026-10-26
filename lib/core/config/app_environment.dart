import 'package:flutter/services.dart' show appFlavor;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';

/// Which build this is, decided at build time by `--flavor dev|prod`.
///
/// prod is locked to the production server; dev talks to appdev and keeps
/// the "Advanced" server override for pointing at a laptop while testing.
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

  /// The self-hosted update manifest, served from the portal's public/
  /// folder (no auth — it's checked before anyone has to be logged in).
  /// Separate per flavor: both servers deploy the same repo, and a dev
  /// phone must never be offered a prod APK (or vice versa) — with
  /// different package ids it would install as a second app, not update.
  static String get releaseManifestPath =>
      isProd ? '/app-releases/latest.json' : '/app-releases/latest-dev.json';

  /// The server every request goes to. In prod any previously saved
  /// override is ignored — an install that was once pointed elsewhere still
  /// talks to production (and only gets production updates).
  static String baseUrl(SharedPreferences prefs) {
    if (!allowsServerOverride) return defaultBaseUrl;
    final saved = prefs.getString(ApiConfig.baseUrlKey)?.trim();
    return (saved == null || saved.isEmpty) ? defaultBaseUrl : saved;
  }
}
