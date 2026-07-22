import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../local_db/checkin_history_dao.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../events/providers/event_provider.dart';
import '../services/attendee_service.dart';
import '../widgets/contact_import_sheet.dart';

class AttendeesScreen extends ConsumerStatefulWidget {
  const AttendeesScreen({super.key});

  @override
  ConsumerState<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends ConsumerState<AttendeesScreen> {
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

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Guests',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.onSurface),
        ),
      ),
      floatingActionButton: eventId != null && _isOnline
          ? FloatingActionButton(
              onPressed: () => _importContacts(eventId),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'Import contacts',
              child: const Icon(Icons.add),
            )
          : null,
      body: eventId == null
          ? const _GuestsEmptySelectionState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _GuestFilterBar(
                    value: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
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
    );
  }
}

class _GuestFilterBar extends StatelessWidget {
  const _GuestFilterBar({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('all', 'All'),
      ('checked', 'Checked in'),
      ('pending', 'Pending'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _FilterTab(
                label: option.$2,
                selected: value == option.$1,
                onTap: () => onChanged(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.muted,
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
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — showing locally scanned guests only',
              style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
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
      error: (e, _) => _GuestsErrorState(onRetry: () => ref.invalidate(attendeesProvider(eventId))),
      data: (attendees) {
        var filtered = attendees;
        if (filter == 'checked') filtered = filtered.where((a) => a.checkedIn).toList();
        if (filter == 'pending') filtered = filtered.where((a) => !a.checkedIn).toList();
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
              children: const [
                SizedBox(height: 120),
                _GuestsListEmptyState(),
              ],
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
                onTap: (attendee) => _showDetail(
                  context,
                  attendee.name,
                  attendee.phone,
                  attendee.contributionAmount,
                  attendee.checkedInAt,
                  attendee.checkedIn,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetail(
    BuildContext context,
    String name,
    String phone,
    String? contribution,
    DateTime? checkedInAt,
    bool checkedIn,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _DetailField(label: 'Phone', value: phone),
              if (contribution != null) ...[
                const SizedBox(height: 12),
                _DetailField(label: 'Contribution', value: contribution),
              ],
              const SizedBox(height: 12),
              _DetailField(
                label: 'Status',
                value: checkedIn ? 'Checked in' : 'Pending',
              ),
              if (checkedInAt != null) ...[
                const SizedBox(height: 12),
                _DetailField(
                  label: 'Checked in at',
                  value: DateFormatter.formatDateTime(checkedInAt),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OfflineHistoryList extends StatelessWidget {
  const _OfflineHistoryList({
    required this.eventId,
    required this.search,
  });

  final String eventId;
  final String search;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: CheckinHistoryDao().getAll(eventId: eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = snapshot.data!;
        if (search.isNotEmpty) {
          items = items
              .where((i) => (i['name'] as String).toLowerCase().contains(search.toLowerCase()))
              .toList();
        }

        if (items.isEmpty) {
          return const Center(child: _GuestsListEmptyState());
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
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
  const _GuestsListSection({
    required this.attendees,
    required this.onTap,
  });

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
            '${attendees.length} guest${attendees.length == 1 ? '' : 's'}',
            style: const TextStyle(
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
                trailing: attendee.checkedIn ? 'Checked in' : 'Pending',
                checkedIn: attendee.checkedIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
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
  });

  final String initials;
  final String name;
  final String subtitle;
  final String trailing;
  final bool checkedIn;

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _GuestsEmptySelectionState extends StatelessWidget {
  const _GuestsEmptySelectionState();

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
              'Select an event first',
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
          child: const Icon(Icons.people_outline, size: 42, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        const Text(
          'No guests found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Try a different filter or tap + to import contacts.',
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
            child: const Icon(Icons.error_outline, color: AppColors.danger, size: 34),
          ),
          const SizedBox(height: 16),
          const Text('Failed to load guests', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}
