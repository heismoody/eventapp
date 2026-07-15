import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  return ref.read(eventServiceProvider).fetchEvents();
});

final activeEventIdProvider = StateProvider<String?>((ref) => null);
final activeEventNameProvider = StateProvider<String?>((ref) => null);

final eventKeysProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  return ref.read(keyVaultProvider).hasKey(eventId);
});

Future<void> selectActiveEvent(WidgetRef ref, EventModel event) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString(ApiConfig.activeEventIdKey, event.id);
  await prefs.setString(ApiConfig.activeEventNameKey, event.name);

  ref.read(activeEventIdProvider.notifier).state = event.id;
  ref.read(activeEventNameProvider.notifier).state = event.name;

  if (event.eventKey != null && event.eventKey!.isNotEmpty) {
    await ref.read(eventServiceProvider).saveEventKey(event.id, event.eventKey!);
  }
}

Future<void> loadActiveEventFromPrefs(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  ref.read(activeEventIdProvider.notifier).state =
      prefs.getString(ApiConfig.activeEventIdKey);
  ref.read(activeEventNameProvider.notifier).state =
      prefs.getString(ApiConfig.activeEventNameKey);
}
