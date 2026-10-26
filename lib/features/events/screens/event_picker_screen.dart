import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../services/event_service.dart';
import '../../../shared/widgets/skeleton_box.dart';

class EventPickerScreen extends ConsumerStatefulWidget {
  const EventPickerScreen({super.key});

  @override
  ConsumerState<EventPickerScreen> createState() => _EventPickerScreenState();
}

class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 160, height: 16),
                  const SizedBox(height: 10),
                  SkeletonBox(width: 120, height: 12, borderRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SkeletonBox(width: 64, height: 24, borderRadius: 999),
          ],
        ),
      ),
    );
  }
}

class _EventPickerScreenState extends ConsumerState<EventPickerScreen> {
  Future<void> _selectEvent(EventModel event) async {
    try {
      if (event.eventKey == null || event.eventKey!.isEmpty) {
        final key = await ref
            .read(eventServiceProvider)
            .fetchEventKey(event.id);
        await ref.read(keyVaultProvider).save(event.id, key);
      } else {
        await ref.read(keyVaultProvider).save(event.id, event.eventKey!);
      }

      await ref.read(eventSelectionControllerProvider).selectActiveEvent(event);
      if (mounted) context.go('/shell/dashboard');
    } catch (e) {
      if (mounted) {
        AppToast.error(
          'Failed to load event key. Enter it manually in Settings.',
        );
      }
    }
  }

  void _showManualKeySheet(EventModel event) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Event Key',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Paste the 64-character hex key for ${event.name}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Event encryption key',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final key = controller.text.trim();
                    if (key.length != 64) {
                      AppToast.warning('Key must be 64 hex characters');
                      return;
                    }
                    await ref.read(keyVaultProvider).save(event.id, key);
                    await ref
                        .read(eventSelectionControllerProvider)
                        .selectActiveEvent(event);
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.go('/shell/dashboard');
                    }
                  },
                  child: const Text('Save Key & Continue'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Event')),
      body: eventsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => const _EventCardSkeleton(),
        ),
        error: (e, _) => Center(child: Text('Failed to load events: $e')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No events available'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              return FutureBuilder<bool>(
                future: ref.read(keyVaultProvider).hasKey(event.id),
                builder: (context, snapshot) {
                  final hasKey = snapshot.data ?? false;
                  return Card(
                    child: ListTile(
                      title: Text(
                        event.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${DateFormatter.formatDate(event.date)} • ${event.venue ?? 'No venue'}',
                      ),
                      trailing: Chip(
                        label: Text(
                          hasKey ? 'Key saved' : 'Key missing',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: hasKey
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                      ),
                      onTap: () => _selectEvent(event),
                      onLongPress: () => _showManualKeySheet(event),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
