import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../../shared/widgets/day_bucket_bar_chart.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../../shared/widgets/speed_dial_fab.dart';
import '../../../shared/widgets/summary_stat_row.dart';
import '../../attendees/services/attendee_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contributions/models/contribution_models.dart';
import '../../contributions/services/contribution_service.dart';
import '../../events/models/event_model.dart';
import '../../events/providers/event_provider.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../../scanner/services/sync_service.dart';
import '../../team/models/team_member_model.dart';
import '../../team/providers/team_provider.dart';

/// Which stretch of the event lifecycle we're in — the dashboard shows
/// different things in each, since an owner may set the event up months
/// before anyone checks in, and check-in/arrivals data is meaningless
/// until then.
enum _DashboardPhase { preparation, live, wrapUp }

_DashboardPhase _resolvePhase({
  required DateTime? eventDate,
  required int checkedInCount,
}) {
  if (eventDate == null) {
    return checkedInCount > 0
        ? _DashboardPhase.live
        : _DashboardPhase.preparation;
  }

  final local = eventDate.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(local.year, local.month, local.day);

  if (eventDay.isBefore(today)) return _DashboardPhase.wrapUp;
  if (checkedInCount > 0 || !eventDay.isAfter(today)) {
    return _DashboardPhase.live;
  }
  return _DashboardPhase.preparation;
}

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
    ref.invalidate(teamMembersProvider);
    final eventId = ref.read(activeEventIdProvider);
    if (eventId != null) {
      ref.invalidate(checkinCountProvider(eventId));
      ref.invalidate(recentCheckinsProvider(eventId));
      ref.invalidate(attendeesProvider(eventId));
      ref.invalidate(contributionCategoriesProvider(eventId));
      ref.invalidate(contributionsProvider(eventId));
    }
  }

  List<_ActivityEntry> _recentActivityEntries({
    required bool isOnline,
    required List<AttendeeRecord> checkins,
    required List<Map<String, dynamic>> localCheckins,
    required List<ContributionRecord> contributions,
    required List<AttendeeRecord> allAttendees,
  }) {
    final entries = <_ActivityEntry>[];

    if (isOnline) {
      for (final guest in checkins) {
        if (guest.checkedInAt == null) continue;
        entries.add(
          _ActivityEntry(
            time: guest.checkedInAt!,
            title: guest.name,
            subtitle: 'Checked in',
            icon: Icons.login_rounded,
            iconColor: AppColors.primary,
          ),
        );
      }
    } else {
      for (final item in localCheckins) {
        final time = DateTime.tryParse(item['checked_in_at'] as String? ?? '');
        if (time == null) continue;
        final synced = (item['synced'] as int?) == 1;
        entries.add(
          _ActivityEntry(
            time: time,
            title: item['name'] as String? ?? 'Guest',
            subtitle: synced ? 'Checked in' : 'Checked in · queued',
            icon: Icons.login_rounded,
            iconColor: AppColors.primary,
          ),
        );
      }
    }

    for (final contribution in contributions) {
      final attendee = allAttendees
          .where((a) => a.id == contribution.attendeeId)
          .firstOrNull;
      entries.add(
        _ActivityEntry(
          time: contribution.createdAt,
          title: attendee?.name ?? 'Guest',
          subtitle: 'Contributed',
          icon: Icons.payments_outlined,
          iconColor: AppColors.success,
          trailing: 'TZS ${compactAmount(contribution.amountValue)}',
        ),
      );
    }

    for (final guest in allAttendees) {
      if (guest.createdAt == null) continue;
      entries.add(
        _ActivityEntry(
          time: guest.createdAt!,
          title: guest.name,
          subtitle: 'Added as guest',
          icon: Icons.person_add_alt_1,
          iconColor: AppColors.accent,
        ),
      );
    }

    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries.take(5).toList();
  }

  List<AttendeeRecord> _recentCheckinsFromAttendees(
    List<AttendeeRecord> attendees,
  ) {
    final checkedIn =
        attendees.where((a) => a.checkedIn && a.checkedInAt != null).toList()
          ..sort((a, b) => b.checkedInAt!.compareTo(a.checkedInAt!));
    return checkedIn.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isEventOwner = user?.isEventOwner == true;
    final eventId = ref.watch(activeEventIdProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final attendeesAsync = eventId != null
        ? ref.watch(attendeesProvider(eventId))
        : const AsyncValue.data(<AttendeeRecord>[]);
    final recentLocalAsync = eventId != null
        ? ref.watch(recentCheckinsProvider(eventId))
        : const AsyncValue.data(<Map<String, dynamic>>[]);

    // True only on the very first fetch (no cached value to fall back on
    // yet) — a pull-to-refresh keeps showing the last-known numbers instead
    // of flashing back to a loading state.
    final guestsLoading =
        eventId != null && attendeesAsync.isLoading && !attendeesAsync.hasValue;

    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    final attendees = attendeesAsync.maybeWhen(
      data: (v) => v,
      orElse: () => <AttendeeRecord>[],
    );
    final localCheckinCount = eventId != null
        ? ref
              .watch(checkinCountProvider(eventId))
              .maybeWhen(data: (v) => v, orElse: () => 0)
        : 0;

    final totalGuests = attendees.length;
    final checkedInCount = attendees.isNotEmpty
        ? attendees.where((a) => a.checkedIn).length
        : localCheckinCount;
    final checkInRate = totalGuests > 0
        ? ((checkedInCount / totalGuests) * 100).round()
        : 0;

    final events = ref
        .watch(eventsProvider)
        .maybeWhen(data: (v) => v, orElse: () => <EventModel>[]);
    final activeEvent = events.where((e) => e.id == eventId).firstOrNull;

    // Categories are just a guest-grouping tag (no money attached) — the
    // real signal for "does this event track contributions" is whether any
    // attendee actually has a pledge or a recorded payment, independent of
    // categories existing at all.
    final usesContributions = attendees.any(
      (a) => a.targetAmountValue > 0 || a.paidAmount > 0,
    );
    final unpaidCount = attendees
        .where(
          (a) =>
              a.paymentStatus == ContributionPaymentStatus.partial ||
              a.paymentStatus == ContributionPaymentStatus.unpaid,
        )
        .length;

    final teamMembersAsync = isEventOwner
        ? ref.watch(teamMembersProvider)
        : null;
    final teamMembers = teamMembersAsync?.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );
    final teamCount = teamMembers?.length;
    final teamLoading =
        teamMembersAsync != null &&
        teamMembersAsync.isLoading &&
        !teamMembersAsync.hasValue;

    final contributionRecords = eventId != null && isEventOwner
        ? ref
              .watch(contributionsProvider(eventId))
              .maybeWhen(data: (v) => v, orElse: () => <ContributionRecord>[])
        : <ContributionRecord>[];

    final phase = _resolvePhase(
      eventDate: activeEvent?.date,
      checkedInCount: checkedInCount,
    );

    final recentFromServer = _isOnline
        ? _recentCheckinsFromAttendees(attendees)
        : <AttendeeRecord>[];
    final recentLocal = recentLocalAsync.maybeWhen(
      data: (v) => v,
      orElse: () => <Map<String, dynamic>>[],
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            title: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: 'Settings',
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
              ? (ref.watch(authInitializedProvider).isLoading
                    ? const _DashboardSkeleton()
                    : const _DashboardEmptyState())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (pending > 0 || !_isOnline)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: _SyncAlertBanner(
                              pendingCount: pending,
                              isOnline: _isOnline,
                            ),
                          ),
                        ),
                      if (activeEvent != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: _EventSnapshotCard(
                              eventName: activeEvent.name,
                              eventDate: activeEvent.date,
                              venue: activeEvent.venue,
                              totalGuests: totalGuests,
                              checkedIn: checkedInCount,
                              checkInRate: checkInRate,
                              isLoading: guestsLoading,
                            ),
                          ),
                        ),
                      _sectionLabel('Summary', topPadding: 28),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: SummaryStatRow(
                            items: [
                              SummaryStatItem(
                                icon: Icons.people_outline,
                                label: 'Guests',
                                value: '$totalGuests',
                                accent: AppColors.primary,
                                isLoading: guestsLoading,
                              ),
                              if (teamCount != null || teamLoading)
                                SummaryStatItem(
                                  icon: Icons.groups_outlined,
                                  label: 'Team',
                                  value: '${teamCount ?? 0}',
                                  accent: AppColors.accent,
                                  isLoading: teamLoading,
                                ),
                              if (isEventOwner)
                                SummaryStatItem(
                                  icon: Icons.payments_outlined,
                                  label: 'Contributions',
                                  value: '$unpaidCount',
                                  accent: !usesContributions
                                      ? AppColors.muted
                                      : unpaidCount > 0
                                      ? AppColors.warning
                                      : AppColors.success,
                                  caption: !usesContributions
                                      ? null
                                      : unpaidCount == 0
                                      ? 'All settled'
                                      : 'unpaid',
                                  isLoading: guestsLoading,
                                ),
                            ],
                          ),
                        ),
                      ),
                      _sectionLabel('Recent activity', topPadding: 24),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _RecentActivitySection(
                            entries: _recentActivityEntries(
                              isOnline: _isOnline,
                              checkins: recentFromServer,
                              localCheckins: recentLocal,
                              contributions: contributionRecords,
                              allAttendees: attendees,
                            ),
                          ),
                        ),
                      ),
                      _sectionLabel('Trends'),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _TrendChartsCard(
                            guestDates: attendees
                                .map((a) => a.createdAt)
                                .whereType<DateTime>()
                                .toList(),
                            teamMembers: teamMembers,
                            contributions: isEventOwner
                                ? contributionRecords
                                : null,
                            isEventOwner: isEventOwner,
                          ),
                        ),
                      ),
                      if (phase == _DashboardPhase.preparation) ...[
                        if (usesContributions && isEventOwner) ...[
                          _sectionLabel('Contributions'),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              child: _EventOverviewSection(
                                attendees: attendees,
                              ),
                            ),
                          ),
                        ],
                      ] else if (phase == _DashboardPhase.live) ...[
                        if (usesContributions &&
                            isEventOwner &&
                            unpaidCount > 0)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                              child: _NeedsAttentionCard(
                                text:
                                    '$unpaidCount guest${unpaidCount == 1 ? '' : 's'} still '
                                    '${unpaidCount == 1 ? 'owes' : 'owe'} a balance',
                                onTap: () => context.go('/shell/attendees'),
                              ),
                            ),
                          ),
                        if (usesContributions && isEventOwner) ...[
                          _sectionLabel('Contributions'),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              child: _EventOverviewSection(
                                attendees: attendees,
                              ),
                            ),
                          ),
                        ],
                      ] else if (phase == _DashboardPhase.live) ...[
                        if (usesContributions &&
                            isEventOwner &&
                            unpaidCount > 0)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                              child: _NeedsAttentionCard(
                                text:
                                    '$unpaidCount guest${unpaidCount == 1 ? '' : 's'} still '
                                    '${unpaidCount == 1 ? 'owes' : 'owe'} a balance',
                                onTap: () => context.go('/shell/attendees'),
                              ),
                            ),
                          ),
                        if (usesContributions && isEventOwner) ...[
                          _sectionLabel('Contributions'),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              child: _EventOverviewSection(
                                attendees: attendees,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
        ),
        // A sibling of the whole Scaffold (header included) rather than a
        // child of its body, so the dim backdrop covers the app bar too —
        // the bottom nav bar lives in MainShell, outside this subtree
        // entirely, so it's never covered regardless.
        if (eventId != null)
          Positioned.fill(
            child: SpeedDialFab(
              actions: [
                SpeedDialAction(
                  icon: Icons.people_outline,
                  label: 'View guests',
                  onTap: () => context.go('/shell/attendees'),
                ),
                if (isEventOwner)
                  SpeedDialAction(
                    icon: Icons.payments_outlined,
                    label: 'Contributions',
                    onTap: () => context.go('/shell/contributions'),
                  ),
                if (isEventOwner)
                  SpeedDialAction(
                    icon: Icons.groups_outlined,
                    label: 'Manage team',
                    onTap: () => context.go('/shell/team'),
                  ),
                if (isEventOwner)
                  SpeedDialAction(
                    icon: Icons.summarize_outlined,
                    label: 'View report',
                    onTap: () => context.push('/shell/report'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  SliverToBoxAdapter _sectionLabel(String text, {double topPadding = 8}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topPadding, 20, 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _SyncAlertBanner extends StatelessWidget {
  const _SyncAlertBanner({required this.pendingCount, required this.isOnline});

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
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Live countdown card (preparation phase) — gradient brown background,
// soft decorative bubbles bleeding off the edges, and a looping diagonal
// light sweep across the gradient itself (not a glowing border).
// ---------------------------------------------------------------------------

class _EventSnapshotCard extends StatefulWidget {
  const _EventSnapshotCard({
    required this.eventName,
    required this.eventDate,
    required this.totalGuests,
    required this.checkedIn,
    required this.checkInRate,
    this.venue,
    this.isLoading = false,
  });

  final String eventName;
  final DateTime eventDate;
  final String? venue;
  final int totalGuests;
  final int checkedIn;
  final int checkInRate;
  final bool isLoading;

  @override
  State<_EventSnapshotCard> createState() => _EventSnapshotCardState();
}

class _EventSnapshotCardState extends State<_EventSnapshotCard> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _computeRemaining());
    });
  }

  Duration _computeRemaining() {
    final diff = widget.eventDate.toLocal().difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void didUpdateWidget(covariant _EventSnapshotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventDate != widget.eventDate) {
      _remaining = _computeRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventName = widget.eventName;
    final eventDate = widget.eventDate;
    final venue = widget.venue;
    final totalGuests = widget.totalGuests;
    final checkedIn = widget.checkedIn;
    final checkInRate = widget.checkInRate;
    final isLoading = widget.isLoading;
    final pending = math.max(totalGuests - checkedIn, 0);
    final isDone = _remaining == Duration.zero;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -44,
              right: -28,
              child: _Bubble(size: 150, opacity: 0.14),
            ),
            const Positioned(
              bottom: -56,
              left: -24,
              child: _Bubble(size: 130, opacity: 0.10),
            ),
            const Positioned(
              top: 54,
              left: -34,
              child: _Bubble(size: 64, opacity: 0.09),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormatter.formatDate(eventDate)}, '
                              '${DateFormatter.formatTime(eventDate)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (venue != null && venue.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    venue,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.celebration_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (isDone)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SnapshotStat(
                          value: _twoDigits(totalGuests),
                          label: 'Guests',
                          isLoading: isLoading,
                        ),
                        const _StatDivider(),
                        _SnapshotStat(
                          value: _twoDigits(checkedIn),
                          label: 'Checked in',
                          isLoading: isLoading,
                        ),
                        const _StatDivider(),
                        _SnapshotStat(
                          value: _twoDigits(pending),
                          label: 'Pending',
                          isLoading: isLoading,
                        ),
                        const _StatDivider(),
                        _SnapshotStat(
                          value: '${_twoDigits(checkInRate)}%',
                          isLoading: isLoading,
                          label: 'Rate',
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CountdownUnit(value: _remaining.inDays, label: 'days'),
                        const _CountdownColon(),
                        _CountdownUnit(
                          value: _remaining.inHours % 24,
                          label: 'hrs',
                        ),
                        const _CountdownColon(),
                        _CountdownUnit(
                          value: _remaining.inMinutes % 60,
                          label: 'mins',
                        ),
                        const _CountdownColon(),
                        _CountdownUnit(
                          value: _remaining.inSeconds % 60,
                          label: 'secs',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _CountdownColon extends StatelessWidget {
  const _CountdownColon();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: 2.5,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class _SnapshotStat extends StatelessWidget {
  const _SnapshotStat({
    required this.value,
    required this.label,
    this.isLoading = false,
  });

  final String value;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLoading)
          SkeletonBox(
            width: 30,
            height: 28,
            borderRadius: 6,
            color: Colors.white.withValues(alpha: 0.4),
          )
        else
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trends — a tabbed (and swipeable, via TabBarView) day-bucketed bar chart
// for Guests / Team / Contributions. Each tab shows a CTA instead of an
// empty chart when that list has no data at all yet.
// ---------------------------------------------------------------------------

class _TrendChartsCard extends StatefulWidget {
  const _TrendChartsCard({
    required this.guestDates,
    required this.teamMembers,
    required this.contributions,
    required this.isEventOwner,
  });

  final List<DateTime> guestDates;
  // null when the viewer isn't an owner (tab hidden); empty when there's
  // simply no team yet (CTA shown).
  final List<TeamMemberModel>? teamMembers;
  final List<ContributionRecord>? contributions;
  final bool isEventOwner;

  @override
  State<_TrendChartsCard> createState() => _TrendChartsCardState();
}

class _TrendChartsCardState extends State<_TrendChartsCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<_TrendTab> get _tabs {
    return [
      _TrendTab(
        label: 'Guests',
        accent: AppColors.primary,
        highlight: AppColors.accent,
        emptyLabel: 'No guests added yet',
        ctaLabel: 'Add guests',
        onCta: () => context.go('/shell/attendees'),
        dates: widget.guestDates,
      ),
      if (widget.isEventOwner)
        _TrendTab(
          label: 'Team',
          accent: AppColors.accent,
          highlight: AppColors.primary,
          emptyLabel: 'No team members yet',
          ctaLabel: 'Add team member',
          onCta: () => context.go('/shell/team'),
          dates: widget.teamMembers?.map((m) => m.createdAt).toList() ?? [],
        ),
      if (widget.isEventOwner)
        _TrendTab(
          label: 'Contributions',
          accent: AppColors.success,
          highlight: AppColors.warning,
          emptyLabel: 'No contributions recorded yet',
          ctaLabel: 'Set up contributions',
          onCta: () => context.go('/shell/contributions'),
          dates: widget.contributions?.map((c) => c.createdAt).toList() ?? [],
          amounts: widget.contributions?.map((c) => c.amountValue).toList(),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void didUpdateWidget(covariant _TrendChartsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLength = _tabs.length;
    if (_tabController.length != newLength) {
      final index = _tabController.index.clamp(0, newLength - 1);
      _tabController.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: index,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: [for (final t in tabs) Tab(text: t.label)],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 292,
            child: TabBarView(
              controller: _tabController,
              children: [for (final t in tabs) _TrendTabBody(tab: t)],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendTab {
  const _TrendTab({
    required this.label,
    required this.accent,
    required this.highlight,
    required this.emptyLabel,
    required this.ctaLabel,
    required this.onCta,
    required this.dates,
    this.amounts,
  });

  final String label;
  final Color accent;
  // Color for today's bar/label, so "now" stands out from the rest of the
  // week — the other brand color, swapped per tab.
  final Color highlight;
  final String emptyLabel;
  final String ctaLabel;
  final VoidCallback onCta;
  final List<DateTime> dates;
  // When set (Contributions), bars show the summed amount per day instead
  // of a plain count — index-aligned with [dates].
  final List<double>? amounts;
}

class _TrendTabBody extends StatelessWidget {
  const _TrendTabBody({required this.tab});

  final _TrendTab tab;

  @override
  Widget build(BuildContext context) {
    if (tab.dates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 28, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(
              tab.emptyLabel,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: tab.onCta, child: Text(tab.ctaLabel)),
          ],
        ),
      );
    }

    return DayBucketBarChart(
      dates: tab.dates,
      amounts: tab.amounts,
      accent: tab.accent,
      highlight: tab.highlight,
    );
  }
}

class _NeedsAttentionCard extends StatelessWidget {
  const _NeedsAttentionCard({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Contributions breakdown (owner-only, events that use contribution
// categories at all — shown in preparation, live and wrap-up phases)
// ---------------------------------------------------------------------------

class _EventOverviewSection extends StatelessWidget {
  const _EventOverviewSection({required this.attendees});

  final List<AttendeeRecord> attendees;

  @override
  Widget build(BuildContext context) {
    final totalGuests = attendees.length;
    double totalCollected = 0;
    double totalTarget = 0;

    final Map<String, _CategoryStats> categoryMap = {};

    for (final a in attendees) {
      totalCollected += a.paidAmount;
      totalTarget += a.targetAmountValue;

      final cat = a.categoryName ?? 'No category';
      final stats = categoryMap[cat] ?? _CategoryStats(name: cat);
      categoryMap[cat] = stats.add(a.paidAmount, a.targetAmountValue);
    }

    final progressFraction = totalTarget > 0
        ? (totalCollected / totalTarget).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progressFraction * 100).round();

    final sortedCategories = categoryMap.values.toList()
      ..sort((a, b) => b.collected.compareTo(a.collected));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverviewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Contributions collected',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _progressColor(progressFraction),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    _progressColor(progressFraction),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TZS ${_compact(totalCollected)} collected',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Target: TZS ${_compact(totalTarget)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (sortedCategories.isNotEmpty)
          _OverviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'By category',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...sortedCategories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${cat.guestCount} guest${cat.guestCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'TZS ${_compact(cat.collected)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (sortedCategories.isNotEmpty) const SizedBox(height: 12),
        const SizedBox(height: 8),
        if (totalGuests == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.group_add_outlined,
                  size: 36,
                  color: AppColors.muted,
                ),
                SizedBox(height: 10),
                Text(
                  'No guests yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Import guests to start tracking contributions',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _progressColor(double fraction) {
    if (fraction >= 0.75) return AppColors.success;
    if (fraction >= 0.4) return AppColors.warning;
    return AppColors.danger;
  }

  String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

class _CategoryStats {
  const _CategoryStats({
    required this.name,
    this.guestCount = 0,
    this.collected = 0,
    this.target = 0,
  });

  final String name;
  final int guestCount;
  final double collected;
  final double target;

  _CategoryStats add(double paid, double tgt) => _CategoryStats(
    name: name,
    guestCount: guestCount + 1,
    collected: collected + paid,
    target: target + tgt,
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// One merged row for the "Recent activity" glance — either a guest
/// check-in or a contribution payment, whichever happened most recently.
class _ActivityEntry {
  const _ActivityEntry({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trailing,
  });

  final DateTime time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? trailing;
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.entries});

  final List<_ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.history, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(
              'No recent activity yet',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _ActivityRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final _ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entry.iconColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(entry.icon, size: 18, color: entry.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (entry.trailing != null)
                Text(
                  entry.trailing!,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: entry.iconColor,
                  ),
                ),
              Text(
                _timeAgo(entry.time),
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormatter.formatDate(time);
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(
                              width: 160,
                              height: 18,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 8),
                            SkeletonBox(
                              width: 120,
                              height: 13,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SkeletonBox(
                        width: 40,
                        height: 40,
                        borderRadius: 20,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0)
                          SkeletonBox(
                            width: 2.5,
                            height: 32,
                            borderRadius: 1,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        Column(
                          children: [
                            SkeletonBox(
                              width: 34,
                              height: 26,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 6),
                            SkeletonBox(
                              width: 44,
                              height: 10,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SkeletonBox(width: 90, height: 15),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 3; i++)
                Column(
                  children: [
                    SkeletonBox(
                      width: 44,
                      height: 44,
                      borderRadius: 22,
                      color: AppColors.border.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 36, height: 14),
                  ],
                ),
            ],
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
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
