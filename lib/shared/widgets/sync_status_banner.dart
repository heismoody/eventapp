import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({
    super.key,
    required this.pendingCount,
    required this.isOnline,
  });

  final int pendingCount;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0 && isOnline) return const SizedBox.shrink();

    final color = isOnline ? AppColors.warning : AppColors.danger;
    final text = isOnline
        ? '$pendingCount check-ins pending sync'
        : 'Offline — $pendingCount queued for sync';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(isOnline ? Icons.sync : Icons.wifi_off, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
