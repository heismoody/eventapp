import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../events/providers/event_provider.dart';
import '../services/sms_log_service.dart';

class SmsLogsScreen extends ConsumerStatefulWidget {
  const SmsLogsScreen({super.key});

  @override
  ConsumerState<SmsLogsScreen> createState() => _SmsLogsScreenState();
}

class _SmsLogsScreenState extends ConsumerState<SmsLogsScreen> {
  String _filter = 'all';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    ref.read(connectivityServiceProvider).isOnline().then((v) {
      if (mounted) setState(() => _isOnline = v);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sent':
        return AppColors.success;
      case 'failed':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);

    if (!_isOnline) {
      return Scaffold(
        appBar: AppBar(title: const Text('SMS Logs')),
        body: const Center(
          child: Text('SMS logs require an internet connection',
              style: TextStyle(color: AppColors.muted)),
        ),
      );
    }

    if (eventId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('SMS Logs')),
        body: const Center(child: Text('Select an event first')),
      );
    }

    final logsAsync = ref.watch(smsLogsProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Logs')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Sent'),
                  selected: _filter == 'sent',
                  onSelected: (_) => setState(() => _filter = 'sent'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Failed'),
                  selected: _filter == 'failed',
                  onSelected: (_) => setState(() => _filter = 'failed'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _filter == 'pending',
                  onSelected: (_) => setState(() => _filter = 'pending'),
                ),
              ],
            ),
          ),
          Expanded(
            child: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          var filtered = logs;
          if (_filter != 'all') {
            filtered = logs.where((l) => l.status == _filter).toList();
          }

          if (filtered.isEmpty) {
            return const Center(child: Text('No SMS logs yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final log = filtered[index];
              return Card(
                child: ListTile(
                  title: Text(log.attendeeName),
                  subtitle: Text(
                    log.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Chip(
                    label: Text(log.status, style: const TextStyle(fontSize: 11)),
                    backgroundColor: _statusColor(log.status).withValues(alpha: 0.15),
                  ),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.attendeeName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(log.phone, style: const TextStyle(color: AppColors.muted)),
                          const SizedBox(height: 16),
                          Text(log.message),
                          const SizedBox(height: 12),
                          Text('Sent: ${DateFormatter.formatDateTime(log.sentAt)}'),
                          if (log.beemRequestId != null)
                            Text('Request ID: ${log.beemRequestId}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}
