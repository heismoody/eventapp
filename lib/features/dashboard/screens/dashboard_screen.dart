import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/sync_status_banner.dart';
import '../../events/providers/event_provider.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../../scanner/services/sync_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    ref.read(connectivityServiceProvider).onStatusChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
      if (online) ref.read(syncServiceProvider).drainQueue();
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _refresh() async {
    await _checkConnectivity();
    if (_isOnline) {
      await ref.read(syncServiceProvider).drainQueue();
    }
    ref.invalidate(pendingSyncCountProvider);
    final eventId = ref.read(activeEventIdProvider);
    if (eventId != null) {
      ref.invalidate(checkinCountProvider(eventId));
      ref.invalidate(recentCheckinsProvider(eventId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventName = ref.watch(activeEventNameProvider) ?? 'No event selected';
    final eventId = ref.watch(activeEventIdProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final checkinAsync = eventId != null
        ? ref.watch(checkinCountProvider(eventId))
        : const AsyncValue.data(0);
    final recentAsync = eventId != null
        ? ref.watch(recentCheckinsProvider(eventId))
        : const AsyncValue.data(<Map<String, dynamic>>[]);

    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    final checkinCount = checkinAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(eventName),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text(_isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: _isOnline
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SyncStatusBanner(pendingCount: pending, isOnline: _isOnline),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Checked In', style: TextStyle(color: Colors.white70)),
                    Text(
                      '$checkinCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  StatCard(label: 'Pending Sync', value: '$pending', color: AppColors.warning),
                  const SizedBox(width: 12),
                  StatCard(label: 'Status', value: _isOnline ? 'Live' : 'Queued'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Recent Check-ins', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          recentAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            ),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (items) {
              if (items.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No check-ins yet', style: TextStyle(color: AppColors.muted))),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final synced = (item['synced'] as int) == 1;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text((item['name'] as String).substring(0, 1).toUpperCase()),
                        ),
                        title: Text(item['name'] as String),
                        subtitle: Text(DateFormatter.formatDateTime(
                            DateTime.parse(item['checked_in_at'] as String))),
                        trailing: Chip(
                          label: Text(synced ? 'Synced' : 'Queued', style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    );
                  },
                  childCount: items.length.clamp(0, 10),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
