import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../local_db/checkin_history_dao.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../events/providers/event_provider.dart';
import '../services/attendee_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendees')),
      body: eventId == null
          ? const Center(child: Text('Select an event first'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
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
                        label: const Text('Checked In'),
                        selected: _filter == 'checked',
                        onSelected: (_) => setState(() => _filter = 'checked'),
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
                  child: _isOnline
                      ? _OnlineAttendeesList(eventId: eventId, filter: _filter, search: _search)
                      : _OfflineHistoryList(eventId: eventId, filter: _filter, search: _search),
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
  });

  final String eventId;
  final String filter;
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(attendeesProvider(eventId));

    return attendeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (attendees) {
        var filtered = attendees;
        if (filter == 'checked') filtered = filtered.where((a) => a.checkedIn).toList();
        if (filter == 'pending') filtered = filtered.where((a) => !a.checkedIn).toList();
        if (search.isNotEmpty) {
          filtered = filtered
              .where((a) => a.name.toLowerCase().contains(search.toLowerCase()))
              .toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final attendee = filtered[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(attendee.name.substring(0, 1))),
                title: Text(attendee.name),
                subtitle: Text(attendee.phone),
                trailing: Chip(
                  label: Text(attendee.checkedIn ? 'Checked In' : 'Pending',
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: attendee.checkedIn
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.muted.withValues(alpha: 0.15),
                ),
                onTap: () => _showDetail(context, attendee.name, attendee.phone,
                    attendee.contributionAmount, attendee.checkedInAt),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetail(BuildContext context, String name, String phone, String? contribution, DateTime? checkedInAt) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(phone),
            if (contribution != null) Text('Contribution: $contribution'),
            if (checkedInAt != null)
              Text('Checked in: ${DateFormatter.formatDateTime(checkedInAt)}'),
          ],
        ),
      ),
    );
  }
}

class _OfflineHistoryList extends StatelessWidget {
  const _OfflineHistoryList({
    required this.eventId,
    required this.filter,
    required this.search,
  });

  final String eventId;
  final String filter;
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item['name'] as String),
                subtitle: Text(item['phone'] as String),
                trailing: Text(DateFormatter.formatTime(
                    DateTime.parse(item['checked_in_at'] as String))),
              ),
            );
          },
        );
      },
    );
  }
}
