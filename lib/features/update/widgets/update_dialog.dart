import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/app_release.dart';
import '../services/update_service.dart';

Future<void> showUpdateDialog(BuildContext context, AppRelease release) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !release.mandatory,
    builder: (context) => PopScope(
      canPop: !release.mandatory,
      child: _UpdateDialogContent(release: release),
    ),
  );
}

class _UpdateDialogContent extends ConsumerStatefulWidget {
  const _UpdateDialogContent({required this.release});

  final AppRelease release;

  @override
  ConsumerState<_UpdateDialogContent> createState() =>
      _UpdateDialogContentState();
}

class _UpdateDialogContentState extends ConsumerState<_UpdateDialogContent> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      final service = ref.read(updateServiceProvider);
      final path = await service.downloadApk(
        widget.release,
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
          _error = 'Download failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update_outlined, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(child: Text('Update available')),
        ],
      ),
      content: _downloading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Downloading version ${release.versionName}…'),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).round()}%',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version ${release.versionName} is ready to install.'),
                if (release.releaseNotes != null &&
                    release.releaseNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    release.releaseNotes!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
      actions: _downloading
          ? null
          : [
              if (!release.mandatory)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Later'),
                ),
              FilledButton(
                onPressed: _startUpdate,
                child: const Text('Update'),
              ),
            ],
    );
  }
}
