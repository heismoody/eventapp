import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../models/event_model.dart';
import 'key_vault.dart';

final keyVaultProvider = Provider<KeyVault>((ref) => KeyVault());

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(ref);
});

class EventService {
  EventService(this._ref);

  final Ref _ref;

  Future<List<EventModel>> fetchEvents() async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(ApiConfig.eventsPath);
    final data = response.data as Map<String, dynamic>;
    final events = data['events'] as List<dynamic>;
    return events.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> fetchEventKey(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(ApiConfig.eventKeyPath(eventId));
    final data = response.data as Map<String, dynamic>;
    return data['eventKey'] as String;
  }

  Future<void> saveEventKey(String eventId, String keyHex) async {
    await _ref.read(keyVaultProvider).save(eventId, keyHex);
  }
}
