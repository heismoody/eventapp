import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../local_db/entries_dao.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../../shared/widgets/speed_dial_fab.dart';
import '../../contributions/widgets/categories_manage_sheet.dart';
import '../../events/providers/event_provider.dart';
import '../services/attendee_service.dart';
import '../widgets/add_guest_sheet.dart';
import '../widgets/attendee_display.dart';
import '../widgets/contact_import_sheet.dart';
import '../widgets/excel_import_sheet.dart';
import '../../../l10n/l10n.dart';

class AttendeesScreen extends ConsumerStatefulWidget {
  const AttendeesScreen({super.key});

  @override
  ConsumerState<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends ConsumerState<AttendeesScreen> {
  /// 'all', a category id, or [_noCategory].
  String _filter = 'all';
  String _search = '';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    ref.read(connectivityServiceProvider).isOnline().then((v) {
      if (mounted) setState(() => _isOnline = v);
    });
  }

  Future<void> _refresh(String eventId) async {
    ref.invalidate(attendeesProvider(eventId));
    if (_isOnline) {
      await ref.read(attendeesProvider(eventId).future);
    }
  }

  Future<void> _importContacts(String eventId) async {
    final imported = await showContactImportSheet(
      context: context,
      ref: ref,
      eventId: eventId,
    );
    if (imported == true && mounted) {
      ref.invalidate(attendeesProvider(eventId));
    }
  }

  Future<void> _importExcel(String eventId) async {
    final imported = await showExcelImportSheet(
      context: context,
      eventId: eventId,
    );
    if (imported == true && mounted) {
      ref.invalidate(attendeesProvider(eventId));
    }
  }

  Future<void> _addGuestManually(String eventId) async {
    final added = await showAddGuestSheet(
      context: context,
      ref: ref,
      eventId: eventId,
    );
    if (added == true && mounted) {
      ref.invalidate(attendeesProvider(eventId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.canvas,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              context.l10n.navGuests,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
          body: eventId == null
              ? const _GuestsEmptySelectionState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: context.l10n.searchByName,
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                    ),
                    if (_isOnline)
                      _CategoryFilterBar(
                        eventId: eventId,
                        value: _filter,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                    if (!_isOnline)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _OfflineBanner(),
                      ),
                    Expanded(
                      child: _isOnline
                          ? _OnlineAttendeesList(
                              eventId: eventId,
                              filter: _filter,
                              search: _search,
                              onRefresh: () => _refresh(eventId),
                            )
                          : _OfflineHistoryList(
                              eventId: eventId,
                              search: _search,
                            ),
                    ),
                  ],
                ),
        ),
        if (eventId != null && _isOnline)
          Positioned.fill(
            child: SpeedDialFab(
              actions: [
                SpeedDialAction(
                  icon: Icons.person_add_alt_1,
                  label: context.l10n.addGuestManually,
                  onTap: () => _addGuestManually(eventId),
                ),
                SpeedDialAction(
                  icon: Icons.contacts_outlined,
                  label: context.l10n.importFromContacts,
                  onTap: () => _importContacts(eventId),
                ),
                SpeedDialAction(
                  icon: Icons.table_view_outlined,
                  label: context.l10n.importFromExcel,
                  onTap: () => _importExcel(eventId),
                ),
                SpeedDialAction(
                  icon: Icons.category_outlined,
                  label: context.l10n.categories,
                  onTap: () => showCategoriesManageSheet(
                    context: context,
                    eventId: eventId,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

const _noCategory = '__none__';

/// "VIP DOUBLE" or "vip double" → "Vip Double", so every pill reads the
/// same however the category was typed in the portal.
String _titleCase(String value) => value
    .trim()
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Filters the guest list by card category (Single, Double, VIP…), with a
/// count on each. Built from the guests themselves, so it only lists
/// categories that have guests. Check-in status shows on each guest row.
class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar({
    required this.eventId,
    required this.value,
    required this.onChanged,
  });

  final String eventId;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendees = ref.watch(attendeesProvider(eventId)).valueOrNull;
    if (attendees == null || attendees.isEmpty) return const SizedBox.shrink();

    final counts = <String, int>{};
    final names = <String, String>{};
    for (final a in attendees) {
      final key = a.categoryId ?? _noCategory;
      counts[key] = (counts[key] ?? 0) + 1;
      names[key] = a.categoryName != null
          ? _titleCase(a.categoryName!)
          : context.l10n.dashNoCategory;
    }
    // Nothing to choose between: every guest is in the same category.
    if (counts.length < 2) return const SizedBox.shrink();

    final keys = counts.keys.toList()
      ..sort((x, y) {
        // "No category" last, the rest by name.
        if (x == _noCategory) return 1;
        if (y == _noCategory) return -1;
        return names[x]!.toLowerCase().compareTo(names[y]!.toLowerCase());
      });
    final options = [
      ('all', context.l10n.filterAll, attendees.length),
      for (final k in keys) (k, names[k]!, counts[k]!),
    ];

    // A category that no longer has guests (after a refresh) falls back
    // to showing everyone.
    final selected = options.any((o) => o.$1 == value) ? value : 'all';

    final pills = [
      for (final option in options)
        _FilterTab(
          label: option.$2,
          count: option.$3,
          selected: selected == option.$1,
          onTap: () => onChanged(option.$1),
        ),
    ];

    // Pills in one row that scrolls sideways, running to the screen edges.
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        itemCount: pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => pills[i],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.onPrimary : AppColors.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: [
                    TextSpan(
                      text: '  $count',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.onPrimary.withValues(alpha: 0.75)
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.offlineLocalGuests,
              style: TextStyle(
                color: AppColors.warning,
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

class _OnlineAttendeesList extends ConsumerWidget {
  const _OnlineAttendeesList({
    required this.eventId,
    required this.filter,
    required this.search,
    required this.onRefresh,
  });

  final String eventId;
  final String filter;
  final String search;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(attendeesProvider(eventId));

    return attendeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _GuestsErrorState(
        onRetry: () => ref.invalidate(attendeesProvider(eventId)),
      ),
      data: (attendees) {
        var filtered = attendees;
        if (filter != 'all') {
          final byCategory = filtered
              .where((a) => (a.categoryId ?? _noCategory) == filter)
              .toList();
          // An empty result means the category is gone (the bar has
          // already fallen back to All), so show everyone.
          if (byCategory.isNotEmpty) filtered = byCategory;
        }
        if (search.isNotEmpty) {
          filtered = filtered
              .where((a) => a.name.toLowerCase().contains(search.toLowerCase()))
              .toList();
        }

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 120), _GuestsListEmptyState()],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              _GuestsListSection(
                attendees: filtered,
                onTap: (attendee) =>
                    context.push('/shell/guests/${attendee.id}'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineHistoryList extends StatelessWidget {
  const _OfflineHistoryList({required this.eventId, required this.search});

  final String eventId;
  final String search;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: EntriesDao().recent(eventId: eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = snapshot.data!;
        if (search.isNotEmpty) {
          items = items
              .where(
                (i) => (i['name'] as String).toLowerCase().contains(
                  search.toLowerCase(),
                ),
              )
              .toList();
        }

        if (items.isEmpty) {
          return const Center(child: _GuestsListEmptyState());
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _GuestCard(
              child: _GuestTile(
                initials: _initials(item['name'] as String),
                name: item['name'] as String,
                subtitle: item['phone'] as String,
                trailing: DateFormatter.formatTime(
                  DateTime.parse(item['checked_in_at'] as String),
                ),
                checkedIn: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _GuestsListSection extends StatelessWidget {
  const _GuestsListSection({required this.attendees, required this.onTap});

  final List<AttendeeRecord> attendees;
  final void Function(AttendeeRecord attendee) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            context.l10n.dashGuestCount(attendees.length),
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        ...attendees.map(
          (attendee) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GuestCard(
              onTap: () => onTap(attendee),
              child: _GuestTile(
                initials: _initials(attendee.name),
                name: attendee.name,
                subtitle: attendee.phone,
                trailing: attendee.admits > 1
                    ? context.l10n.enteredShort(
                        attendee.enteredCount,
                        attendee.admits,
                      )
                    : attendee.checkedIn
                    ? context.l10n.dashCheckedIn
                    : context.l10n.pending,
                checkedIn: attendee.checkedIn,
                paymentStatus: attendee.paymentStatus,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.trailing,
    required this.checkedIn,
    this.paymentStatus = ContributionPaymentStatus.none,
  });

  final String initials;
  final String name;
  final String subtitle;
  final String trailing;
  final bool checkedIn;
  final ContributionPaymentStatus paymentStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: TextStyle(
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (paymentStatus != ContributionPaymentStatus.none) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: contributionStatusColor(
                        paymentStatus,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      contributionStatusLabel(paymentStatus),
                      style: TextStyle(
                        color: contributionStatusColor(paymentStatus),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (checkedIn ? AppColors.success : AppColors.muted)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                color: checkedIn ? AppColors.success : AppColors.muted,
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

class _GuestsEmptySelectionState extends StatelessWidget {
  const _GuestsEmptySelectionState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 56, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              context.l10n.selectEventFirst,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestsListEmptyState extends StatelessWidget {
  const _GuestsListEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.people_outline, size: 42, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.noGuestsFound,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.noGuestsFoundHint,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _GuestsErrorState extends StatelessWidget {
  const _GuestsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: AppColors.danger, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.loadGuestsFailedTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
