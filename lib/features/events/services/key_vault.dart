import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyVault {
  KeyVault() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _keyFor(String eventId) => 'es_key_$eventId';

  Future<void> save(String eventId, String keyHex) async {
    await _storage.write(key: _keyFor(eventId), value: keyHex);
  }

  Future<String?> get(String eventId) => _storage.read(key: _keyFor(eventId));

  Future<bool> hasKey(String eventId) async {
    final value = await get(eventId);
    return value != null && value.isNotEmpty;
  }
}
