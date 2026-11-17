import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../services/play_update_service.dart';

/// Keeps the Play build up to date without a trip to the Play Store.
///
/// When the app opens or comes back to the front it asks Play for a newer
/// version. An urgent release (priority 4–5, set by CI) gets Play's
/// full-screen update. Any other release gets Play's small "Update?"
/// prompt, downloads in the background, then this shows a Restart bar.
/// Nothing is asked while someone is scanning guests at the door.
class PlayUpdateGate extends ConsumerStatefulWidget {
  const PlayUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlayUpdateGate> createState() => _PlayUpdateGateState();
}

class _PlayUpdateGateState extends ConsumerState<PlayUpdateGate>
    with WidgetsBindingObserver {
  static const _declinedKey = 'play_update_declined_at';

  /// How long a "No thanks" to a normal update holds.
  static const _askAgainAfter = Duration(days: 2);

  /// At most one check this often, apart from a finished download.
  static const _checkEvery = Duration(hours: 1);

  final _service = PlayUpdateService();
  StreamSubscription<String>? _states;
  DateTime? _lastCheck;
  bool _busy = false;
  bool _readyToInstall = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _states = _service.installStates.listen((status) {
      if (!mounted) return;
      setState(() => _readyToInstall = status == 'downloaded');
    });
    // Give the first screen a moment before talking to Play.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _check();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _states?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  bool get _atTheDoor {
    final path = ref
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    return path.startsWith('/scan') || path.startsWith('/shell/scanner');
  }

  Future<void> _check() async {
    if (_busy) return;
    _busy = true;
    try {
      final info = await _service.check();
      if (!mounted) return;

      // Downloaded while the app was away: offer the restart.
      if (info.installStatus == 'downloaded') {
        setState(() => _readyToInstall = true);
        return;
      }

      // An urgent update that was interrupted must carry on (Play's rule).
      if (info.availability == 'in_progress') {
        await _service.start(immediate: true);
        return;
      }

      final now = DateTime.now();
      if (_lastCheck != null && now.difference(_lastCheck!) < _checkEvery) {
        return;
      }
      if (info.availability != 'available' || _atTheDoor) return;
      _lastCheck = now;

      if (info.urgent && info.immediateAllowed) {
        await _service.start(immediate: true);
        return;
      }

      if (!info.flexibleAllowed || _declinedRecently(now)) return;
      final answer = await _service.start(immediate: false);
      if (answer == 'declined') {
        await ref
            .read(sharedPreferencesProvider)
            .setString(_declinedKey, now.toIso8601String());
      }
    } finally {
      _busy = false;
    }
  }

  bool _declinedRecently(DateTime now) {
    final raw = ref.read(sharedPreferencesProvider).getString(_declinedKey);
    final at = raw == null ? null : DateTime.tryParse(raw);
    return at != null && now.difference(at) < _askAgainAfter;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_readyToInstall)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _RestartBar(onRestart: _service.complete),
            ),
          ),
      ],
    );
  }
}

class _RestartBar extends StatelessWidget {
  const _RestartBar({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.primaryDark,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(Icons.system_update_rounded, color: AppColors.onPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.updateReadyTitle,
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.updateReadyBody,
                    style: TextStyle(
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRestart,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(48, 48),
              ),
              child: Text(
                l10n.updateRestart,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
