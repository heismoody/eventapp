import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What Play says about updates for this install.
class PlayUpdateInfo {
  const PlayUpdateInfo({
    required this.availability,
    this.priority = 0,
    this.flexibleAllowed = false,
    this.immediateAllowed = false,
    this.installStatus = 'unknown',
  });

  /// "available", "in_progress" (an immediate update was interrupted),
  /// "none" or "unknown" (not from Play, offline).
  final String availability;

  /// 0–5, set per release when CI uploads it. 4 and up means urgent.
  final int priority;
  final bool flexibleAllowed;
  final bool immediateAllowed;

  /// "downloaded" when a flexible update is waiting for a restart.
  final String installStatus;

  bool get urgent => priority >= 4;

  factory PlayUpdateInfo.fromMap(Map<dynamic, dynamic> map) => PlayUpdateInfo(
    availability: map['availability'] as String? ?? 'unknown',
    priority: (map['priority'] as num?)?.toInt() ?? 0,
    flexibleAllowed: map['flexibleAllowed'] == true,
    immediateAllowed: map['immediateAllowed'] == true,
    installStatus: map['installStatus'] as String? ?? 'unknown',
  );
}

/// Google Play in-app updates, through the `cardly/play_update` channel in
/// MainActivity (PlayUpdates.kt). Only the Play build uses this. Every
/// failure reads as "no update": a check must never get in the way.
class PlayUpdateService {
  PlayUpdateService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onInstallState') {
        final status = (call.arguments as Map)['status'] as String?;
        if (status != null) _installStates.add(status);
      }
    });
  }

  static const _channel = MethodChannel('cardly/play_update');

  final _installStates = StreamController<String>.broadcast();

  /// "downloading", "downloaded", "installed", "failed", … while a
  /// flexible update downloads.
  Stream<String> get installStates => _installStates.stream;

  Future<PlayUpdateInfo> check() async {
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('check');
      return map == null
          ? const PlayUpdateInfo(availability: 'unknown')
          : PlayUpdateInfo.fromMap(map);
    } catch (error) {
      debugPrint('[play-update] check failed: $error');
      return const PlayUpdateInfo(availability: 'unknown');
    }
  }

  /// Shows Play's own update screen. Returns "accepted", "declined",
  /// "unavailable" or "failed".
  Future<String> start({required bool immediate}) async {
    try {
      return await _channel.invokeMethod<String>('start', {
            'type': immediate ? 'immediate' : 'flexible',
          }) ??
          'failed';
    } catch (error) {
      debugPrint('[play-update] start failed: $error');
      return 'failed';
    }
  }

  /// Installs a downloaded flexible update. The app restarts.
  Future<void> complete() async {
    try {
      await _channel.invokeMethod<void>('complete');
    } catch (error) {
      debugPrint('[play-update] complete failed: $error');
    }
  }
}
