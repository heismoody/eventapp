import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../attendees/services/attendee_service.dart';
import '../../auth/providers/auth_provider.dart';
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
    ref.invalidate(eventsProvider);
    final eventId = ref.read(activeEventIdProvider);
    if (eventId != null) {
      ref.invalidate(checkinCountProvider(eventId));
      ref.invalidate(recentCheckinsProvider(eventId));
      ref.invalidate(attendeesProvider(eventId));
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int _daysUntilEvent(DateTime date) {
    final now = DateTime.now();
    final eventDay = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return eventDay.difference(today).inDays;
  }

  String _eventCountdownLabel(DateTime date) {
    final days = _daysUntilEvent(date);
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days > 1) return 'In $days days';
    if (days == -1) return 'Yesterday';
    return '${days.abs()} days ago';
  }

  List<AttendeeRecord> _recentCheckinsFromAttendees(List<AttendeeRecord> attendees) {
    final checkedIn = attendees.where((a) => a.checkedIn && a.checkedInAt != null).toList()
      ..sort((a, b) => b.checkedInAt!.compareTo(a.checkedInAt!));
    return checkedIn.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final eventId = ref.watch(activeEventIdProvider);
    final eventName = ref.watch(activeEventNameProvider) ?? 'No event selected';
    final eventsAsync = ref.watch(eventsProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final attendeesAsync = eventId != null
        ? ref.watch(attendeesProvider(eventId))
        : const AsyncValue.data(<AttendeeRecord>[]);
    final recentLocalAsync = eventId != null
        ? ref.watch(recentCheckinsProvider(eventId))
        : const AsyncValue.data(<Map<String, dynamic>>[]);

    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    final attendees = attendeesAsync.maybeWhen(data: (v) => v, orElse: () => <AttendeeRecord>[]);
    final localCheckinCount = eventId != null
        ? ref.watch(checkinCountProvider(eventId)).maybeWhen(data: (v) => v, orElse: () => 0)
        : 0;

    final totalGuests = attendees.length;
    final checkedInCount = attendees.isNotEmpty
        ? attendees.where((a) => a.checkedIn).length
        : localCheckinCount;
    final progress = totalGuests > 0 ? checkedInCount / totalGuests : 0.0;
    final checkInRate = totalGuests > 0 ? ((checkedInCount / totalGuests) * 100).round() : 0;

    final activeEvent = eventsAsync.maybeWhen(
      data: (events) {
        if (eventId == null) return null;
        for (final event in events) {
          if (event.id == eventId) return event;
        }
        return null;
      },
      orElse: () => null,
    );

    final recentFromServer = _isOnline ? _recentCheckinsFromAttendees(attendees) : <AttendeeRecord>[];
    final recentLocal = recentLocalAsync.maybeWhen(data: (v) => v, orElse: () => <Map<String, dynamic>>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Account & settings',
              onPressed: () => context.go('/shell/settings'),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  _userInitials(user?.name),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: eventId == null
          ? const _DashboardEmptyState()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        '${_greeting()}, ${user?.name.split(' ').first ?? 'there'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _EventOverviewCard(
                        eventName: eventName,
                        date: activeEvent?.date,
                        venue: activeEvent?.venue,
                        countdownLabel: activeEvent != null
                            ? _eventCountdownLabel(activeEvent.date)
                            : null,
                        daysUntil: activeEvent != null ? _daysUntilEvent(activeEvent.date) : null,
                      ),
                    ),
                  ),
                  if (pending > 0 || !_isOnline)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _SyncAlertBanner(pendingCount: pending, isOnline: _isOnline),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _CheckInHeroCard(
                        checkedIn: checkedInCount,
                        totalGuests: totalGuests,
                        progress: progress,
                        checkInRate: checkInRate,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: _QuickActionsRow(isEventOwner: user?.isEventOwner == true),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 20, 10),
                      child: Text(
                        'Recent arrivals',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_isOnline && recentFromServer.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: recentFromServer.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final guest = recentFromServer[index];
                          return _RecentGuestCard(
                            name: guest.name,
                            subtitle: DateFormatter.formatDateTime(guest.checkedInAt),
                            trailing: guest.contributionAmount,
                          );
                        },
                      ),
                    )
                  else if (!_isOnline && recentLocal.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: recentLocal.length.clamp(0, 8),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = recentLocal[index];
                          final synced = (item['synced'] as int) == 1;
                          return _RecentGuestCard(
                            name: item['name'] as String,
                            subtitle: DateFormatter.formatDateTime(
                              DateTime.parse(item['checked_in_at'] as String),
                            ),
                            trailing: synced ? null : 'Queued',
                          );
                        },
                      ),
                    )
                  else
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                        child: _RecentEmptyState(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SyncAlertBanner extends StatelessWidget {
  const _SyncAlertBanner({
    required this.pendingCount,
    required this.isOnline,
  });

  final int pendingCount;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.warning : AppColors.danger;
    final text = isOnline
        ? '$pendingCount check-in${pendingCount == 1 ? '' : 's'} waiting to sync'
        : 'Offline — $pendingCount check-in${pendingCount == 1 ? '' : 's'} queued';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(isOnline ? Icons.sync : Icons.wifi_off, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventOverviewCard extends StatelessWidget {
  const _EventOverviewCard({
    required this.eventName,
    this.date,
    this.venue,
    this.countdownLabel,
    this.daysUntil,
  });

  final String eventName;
  final DateTime? date;
  final String? venue;
  final String? countdownLabel;
  final int? daysUntil;

  @override
  Widget build(BuildContext context) {
    final isToday = daysUntil == 0;
    final isPast = daysUntil != null && daysUntil! < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date != null)
                  Text(
                    DateFormatter.formatDate(date),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  ),
                const SizedBox(height: 4),
                Text(
                  eventName,
                  style: TextStyle(
                    color: date != null ? AppColors.muted : AppColors.onSurface,
                    fontWeight: date != null ? FontWeight.w600 : FontWeight.w700,
                    fontSize: date != null ? 14 : 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (venue != null && venue!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    venue!,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (countdownLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isToday
                        ? AppColors.success
                        : isPast
                            ? AppColors.muted
                            : AppColors.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                countdownLabel!,
                style: TextStyle(
                  color: isToday
                      ? AppColors.success
                      : isPast
                          ? AppColors.muted
                          : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckInHeroCard extends StatelessWidget {
  const _CheckInHeroCard({
    required this.checkedIn,
    required this.totalGuests,
    required this.progress,
    required this.checkInRate,
  });

  final int checkedIn;
  final int totalGuests;
  final double progress;
  final int checkInRate;

  @override
  Widget build(BuildContext context) {
    final guestLabel = totalGuests > 0 ? '/ $totalGuests guests' : ' guests';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'CHECKED IN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (totalGuests > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$checkInRate%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$checkedIn',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                guestLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: totalGuests > 0 ? progress.clamp(0.0, 1.0) : null,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.isEventOwner});

  final bool isEventOwner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Quick actions',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _QuickActionChip(
                icon: Icons.qr_code_scanner,
                label: 'Scan guest',
                onTap: () => context.go('/shell/scanner'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionChip(
                icon: Icons.people_outline,
                label: 'View guests',
                onTap: () => context.go('/shell/attendees'),
              ),
            ),
            if (isEventOwner) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionChip(
                  icon: Icons.groups_outlined,
                  label: 'Manage team',
                  onTap: () => context.go('/shell/team'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentGuestCard extends StatelessWidget {
  const _RecentGuestCard({
    required this.name,
    required this.subtitle,
    this.trailing,
  });

  final String name;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                trailing!,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.login_outlined, size: 36, color: AppColors.muted),
          SizedBox(height: 10),
          Text(
            'No check-ins yet',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
          ),
          SizedBox(height: 4),
          Text(
            'Scan a guest QR code to see arrivals here',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 56, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              'Select an event to view your dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

String _userInitials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}
