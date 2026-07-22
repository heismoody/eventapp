import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/scanner/models/scan_result.dart';
import '../../features/scanner/models/scanned_guest.dart';

Future<void> showGuestResultSheet(
  BuildContext context, {
  required ScanResult result,
  VoidCallback? onDismiss,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildContent(result),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss?.call();
                },
                child: const Text('Continue Scanning'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildContent(ScanResult result) {
  switch (result.type) {
    case ScanResultType.success:
      return _SuccessContent(guest: result.guest!);
    case ScanResultType.duplicate:
      return _DuplicateContent(
        guest: result.guest!,
        checkedInAt: result.checkedInAt,
      );
    case ScanResultType.invalid:
      return const _InvalidContent();
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.guest});

  final ScannedGuest guest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 56),
        const SizedBox(height: 12),
        const Text('Checked In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(guest.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(guest.phone, style: const TextStyle(color: AppColors.muted)),
        if (guest.contributionAmount != null) ...[
          const SizedBox(height: 12),
          Chip(
            label: Text('Contribution: ${guest.contributionAmount}'),
            backgroundColor: AppColors.background,
          ),
        ],
      ],
    );
  }
}

class _DuplicateContent extends StatelessWidget {
  const _DuplicateContent({required this.guest, this.checkedInAt});

  final ScannedGuest guest;
  final DateTime? checkedInAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 56),
        const SizedBox(height: 12),
        const Text('Already Checked In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(guest.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          'Registered at ${DateFormatter.formatTime(checkedInAt)}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _InvalidContent extends StatelessWidget {
  const _InvalidContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.error_outline, color: AppColors.danger, size: 56),
        SizedBox(height: 12),
        Text('Invalid QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text(
          'Could not decrypt this code. Check your event key in Settings.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}
