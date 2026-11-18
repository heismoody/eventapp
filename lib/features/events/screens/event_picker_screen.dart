import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/l10n.dart';
import '../../auth/services/session_manager.dart';
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
                style: TextStyle(color: AppColors.muted),
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

  /// Always a way out: the list can fail to load, or be empty, for a
  /// reason only another account fixes.
  Future<void> _signOut() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logOutQuestion),
        content: Text(l10n.logOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(sessionManagerProvider).handleSessionExpired();
    if (mounted) context.go('/login?skip=1');
  }

  Future<void> _reload() async {
    ref.invalidate(eventsProvider);
    try {
      await ref.read(eventsProvider.future);
    } catch (_) {
      // The error state shows it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectEventTitle),
        actions: [
          IconButton(
            tooltip: l10n.logOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => const _EventCardSkeleton(),
        ),
        error: (e, _) {
          debugPrint('[events] load failed: $e');
          return _Message(
            icon: Icons.cloud_off_rounded,
            title: l10n.eventsLoadFailedTitle,
            body: l10n.eventsLoadFailedBody,
            primary: FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
            ),
            secondary: TextButton(
              onPressed: _signOut,
              child: Text(l10n.logOut),
            ),
          );
        },
        data: (events) {
          if (events.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: _Message(
                      icon: Icons.event_busy_rounded,
                      title: l10n.noEventsTitle,
                      body: l10n.noEventsBody,
                      secondary: TextButton(
                        onPressed: _signOut,
                        child: Text(l10n.logOut),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
                          '${DateFormatter.formatDate(event.date)}, ${event.venue ?? l10n.noVenue}',
                        ),
                        trailing: Chip(
                          label: Text(
                            hasKey
                                ? l10n.eventKeySavedChip
                                : l10n.eventKeyMissing,
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
            ),
          );
        },
      ),
    );
  }
}

/// Centered icon, title, explanation and what to do next.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.primary,
    this.secondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            if (primary != null) ...[const SizedBox(height: 24), primary!],
            if (secondary != null) ...[const SizedBox(height: 8), secondary!],
          ],
        ),
      ),
    );
  }
}
