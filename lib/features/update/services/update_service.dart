import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../models/app_release.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref);
});

/// Drives the self-hosted Android update flow: check the portal's static
/// release manifest, download the APK if a newer one exists, hand it to
/// Android's own package installer. There's no Play Store here, so this is
/// the whole distribution channel.
class UpdateService {
  UpdateService(this._ref);

  final Ref _ref;

  /// Returns the latest published release if it's newer than the running
  /// app build, or null when already current or the check fails (e.g. no
  /// connectivity) — a failed check should never block using the app.
  Future<AppRelease?> checkForUpdate() async {
    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get(AppEnvironment.releaseManifestPath);
      final release = AppRelease.fromJson(
        response.data as Map<String, dynamic>,
      );

      final info = await PackageInfo.fromPlatform();
      final installedCode = int.tryParse(info.buildNumber) ?? 0;

      return release.versionCode > installedCode ? release : null;
    } catch (_) {
      return null;
    }
  }

  /// Downloads the APK, reporting progress from 0.0 to 1.0, and returns the
  /// local file path once it's complete.
  Future<String> downloadApk(
    AppRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/cardly-${release.versionName}.apk';

    // A plain Dio instance — apkUrl is already absolute, and this download
    // has nothing to do with the authenticated API client.
    await Dio().download(
      release.apkUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    return filePath;
  }

  /// Hands the downloaded APK to Android's package installer. Android
  /// always shows its own install confirmation — there's no way to make
  /// this fully silent short of the app being a device-owner/MDM app.
  Future<void> installApk(String filePath) async {
    await OpenFilex.open(filePath);
  }
}

final appUpdateProvider = FutureProvider<AppRelease?>((ref) async {
  return ref.read(updateServiceProvider).checkForUpdate();
});
