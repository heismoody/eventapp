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

final eventSelectionControllerProvider = Provider<EventSelectionController>((ref) {
  return EventSelectionController(ref);
});

class EventSelectionController {
  EventSelectionController(this._ref);

  final Ref _ref;

  Future<void> selectActiveEvent(EventModel event) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(ApiConfig.activeEventIdKey, event.id);
    await prefs.setString(ApiConfig.activeEventNameKey, event.name);

    _ref.read(activeEventIdProvider.notifier).state = event.id;
    _ref.read(activeEventNameProvider.notifier).state = event.name;

    if (event.eventKey != null && event.eventKey!.isNotEmpty) {
      await _ref.read(eventServiceProvider).saveEventKey(event.id, event.eventKey!);
    }
  }

  Future<void> loadActiveEventFromPrefs() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    _ref.read(activeEventIdProvider.notifier).state =
        prefs.getString(ApiConfig.activeEventIdKey);
    _ref.read(activeEventNameProvider.notifier).state =
        prefs.getString(ApiConfig.activeEventNameKey);
  }

  Future<bool> initializeOwnedEvent(String ownedEventId) async {
    if (ownedEventId.isEmpty) {
      return false;
    }

    final events = await _ref.read(eventServiceProvider).fetchEvents();
    EventModel? event;
    for (final item in events) {
      if (item.id == ownedEventId) {
        event = item;
        break;
      }
    }
    if (event == null) {
      return false;
    }

    if (event.eventKey == null || event.eventKey!.isEmpty) {
      final key = await _ref.read(eventServiceProvider).fetchEventKey(event.id);
      await _ref.read(keyVaultProvider).save(event.id, key);
      await selectActiveEvent(
        EventModel(
          id: event.id,
          name: event.name,
          description: event.description,
          date: event.date,
          venue: event.venue,
          eventKey: key,
        ),
      );
    } else {
      await selectActiveEvent(event);
    }

    return true;
  }
}
