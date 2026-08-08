import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../attendees/services/attendee_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contributions/services/contribution_service.dart';
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
      ref.invalidate(smsCreditsProvider(eventId));
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
    final eventId = ref.watch(activeEventIdProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final attendeesAsync = eventId != null
        ? ref.watch(attendeesProvider(eventId))
        : const AsyncValue.data(<AttendeeRecord>[]);
    final recentLocalAsync = eventId != null
        ? ref.watch(recentCheckinsProvider(eventId))
        : const AsyncValue.data(<Map<String, dynamic>>[]);

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
    final progress = totalGuests > 0 ? checkedInCount / totalGuests : 0.0;
    final checkInRate = totalGuests > 0
        ? ((checkedInCount / totalGuests) * 100).round()
        : 0;
    final smsCreditsAsync = eventId != null
        ? ref.watch(smsCreditsProvider(eventId))
        : const AsyncValue.data(null);

    final recentFromServer = _isOnline
        ? _recentCheckinsFromAttendees(attendees)
        : <AttendeeRecord>[];
    final recentLocal = recentLocalAsync.maybeWhen(
      data: (v) => v,
      orElse: () => <Map<String, dynamic>>[],
    );

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
                  if (pending > 0 || !_isOnline)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _SyncAlertBanner(
                          pendingCount: pending,
                          isOnline: _isOnline,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _DashboardHeroSlideshow(
                        checkedIn: checkedInCount,
                        totalGuests: totalGuests,
                        progress: progress,
                        checkInRate: checkInRate,
                        allocatedMessages: smsCreditsAsync.maybeWhen(
                          data: (value) => value?.allocated ?? 0,
                          orElse: () => 0,
                        ),
                        usedMessages: smsCreditsAsync.maybeWhen(
                          data: (value) => value?.used ?? 0,
                          orElse: () => 0,
                        ),
                        availableMessages: smsCreditsAsync.maybeWhen(
                          data: (value) => value?.available ?? 0,
                          orElse: () => 0,
                        ),
                        isCreditsLoading: smsCreditsAsync.isLoading,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: _QuickActionsRow(
                        isEventOwner: user?.isEventOwner == true,
                      ),
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
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final guest = recentFromServer[index];
                          return _RecentGuestCard(
                            name: guest.name,
                            subtitle: DateFormatter.formatDateTime(
                              guest.checkedInAt,
                            ),
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
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
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

class _DashboardHeroSlideshow extends StatefulWidget {
  const _DashboardHeroSlideshow({
    required this.checkedIn,
    required this.totalGuests,
    required this.progress,
    required this.checkInRate,
    required this.allocatedMessages,
    required this.usedMessages,
    required this.availableMessages,
    required this.isCreditsLoading,
  });

  final int checkedIn;
  final int totalGuests;
  final double progress;
  final int checkInRate;
  final int allocatedMessages;
  final int usedMessages;
  final int availableMessages;
  final bool isCreditsLoading;

  @override
  State<_DashboardHeroSlideshow> createState() =>
      _DashboardHeroSlideshowState();
}

class _DashboardHeroSlideshowState extends State<_DashboardHeroSlideshow> {
  static const _slideDuration = Duration(seconds: 5);

  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(_slideDuration, (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % 2;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final slideHeight = 150 + ((textScale - 1) * 36).clamp(0.0, 28.0);

    return Column(
      children: [
        SizedBox(
          height: slideHeight,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _HeroSlideShell(
                child: _CheckInSlideContent(
                  checkedIn: widget.checkedIn,
                  totalGuests: widget.totalGuests,
                  progress: widget.progress,
                  checkInRate: widget.checkInRate,
                ),
              ),
              _HeroSlideShell(
                child: _SmsAllocatedSlideContent(
                  allocatedMessages: widget.allocatedMessages,
                  usedMessages: widget.usedMessages,
                  availableMessages: widget.availableMessages,
                  isLoading: widget.isCreditsLoading,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeroSlideShell extends StatelessWidget {
  const _HeroSlideShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: Align(
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}

class _HeroSlideContent extends StatelessWidget {
  const _HeroSlideContent({
    required this.label,
    required this.badge,
    required this.value,
    required this.suffix,
    this.progress,
    this.showProgressBar = true,
  });

  final String label;
  final String? badge;
  final String value;
  final String suffix;
  final double? progress;
  final bool showProgressBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
            Flexible(
              child: Text(
                suffix,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (showProgressBar && progress != null) ...[
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckInSlideContent extends StatelessWidget {
  const _CheckInSlideContent({
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

    return _HeroSlideContent(
      label: 'CHECKED IN',
      badge: totalGuests > 0 ? '$checkInRate%' : null,
      value: '$checkedIn',
      suffix: guestLabel,
      progress: totalGuests > 0 ? progress.clamp(0.0, 1.0) : null,
    );
  }
}

class _SmsAllocatedSlideContent extends StatelessWidget {
  const _SmsAllocatedSlideContent({
    required this.allocatedMessages,
    required this.usedMessages,
    required this.availableMessages,
    required this.isLoading,
  });

  final int allocatedMessages;
  final int usedMessages;
  final int availableMessages;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final badge = isLoading
        ? '...'
        : '$usedMessages used · $availableMessages left';

    return _HeroSlideContent(
      label: 'SMS ALLOCATED',
      badge: badge,
      value: isLoading ? '—' : '$allocatedMessages',
      suffix: ' messages',
      showProgressBar: false,
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
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : '?';

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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
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
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
