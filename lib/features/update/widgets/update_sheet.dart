import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../models/app_release.dart';
import '../services/update_service.dart';

/// Offers a newer Cardly Dev build: what's new, then the download with its
/// progress, then Android's own install prompt. Shown when the app finds
/// an update on start and when the "new version is out" notification is
/// tapped. A required update can't be put off: no Later, and the sheet
/// can't be swiped away, tapped away or closed with Back.
Future<void> showUpdateSheet(BuildContext context, AppRelease release) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: !release.mandatory,
    enableDrag: !release.mandatory,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _UpdateSheet(release: release),
  );
}

class _UpdateSheet extends ConsumerStatefulWidget {
  const _UpdateSheet({required this.release});

  final AppRelease release;

  @override
  ConsumerState<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends ConsumerState<_UpdateSheet> {
  bool _downloading = false;
  double _progress = 0;
  bool _failed = false;

  AppRelease get _release => widget.release;

  String get _version => '${_release.versionName} (${_release.versionCode})';

  Future<void> _update() async {
    setState(() {
      _downloading = true;
      _failed = false;
      _progress = 0;
    });
    try {
      final service = ref.read(updateServiceProvider);
      final path = await service.downloadApk(
        _release,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await service.installApk(path);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final notes = _release.releaseNotes?.trim() ?? '';

    return PopScope(
      // Back and a tap outside don't close it mid-download, or ever when
      // the update is required.
      canPop: !_release.mandatory && !_downloading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _release.mandatory
                    ? Colors.transparent
                    : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.updateAvailableTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _downloading
                  ? _Downloading(
                      key: const ValueKey('downloading'),
                      version: _version,
                      progress: _progress,
                    )
                  : Column(
                      key: const ValueKey('offer'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.updateReadyToInstall(_version),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurface,
                            height: 1.4,
                          ),
                        ),
                        if (_release.mandatory) ...[
                          const SizedBox(height: 6),
                          Text(
                            l10n.updateRequired,
                            style: TextStyle(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryAlt,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.updateWhatsNew,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notes,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_failed) ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n.updateDownloadFailed,
                            style: TextStyle(
                              color: AppColors.danger,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _downloading ? null : _update,
                    child: Text(
                      _downloading
                          ? l10n.updateDownloadingShort
                          : (_failed ? l10n.tryAgain : l10n.updateNow),
                    ),
                  ),
                ),
                if (!_release.mandatory && !_downloading) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.updateLater),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Downloading extends StatelessWidget {
  const _Downloading({
    super.key,
    required this.version,
    required this.progress,
  });

  final String version;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.updateDownloading(version),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            minHeight: 8,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.updateInstallHint,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
