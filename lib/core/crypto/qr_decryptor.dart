import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../features/scanner/models/scanned_guest.dart';

class QrDecryptor {
  static const String prefix = 'ES1:';
  static const int ivLength = 12;
  static const int tagLength = 16;

  static Future<ScannedGuest?> decrypt(String encoded, String keyHex) async {
    try {
      final trimmed = encoded.trim();
      if (!trimmed.startsWith(prefix)) return null;
      if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(keyHex)) return null;

      final payload = trimmed.substring(prefix.length);
      final combined = base64Url.decode(_normalizeBase64Url(payload));
      if (combined.length < ivLength + tagLength + 1) return null;

      final iv = combined.sublist(0, ivLength);
      final tag = combined.sublist(combined.length - tagLength);
      final ciphertext = combined.sublist(ivLength, combined.length - tagLength);

      final keyBytes = _hexToBytes(keyHex);
      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(keyBytes);

      final secretBox = SecretBox(
        ciphertext,
        nonce: iv,
        mac: Mac(tag),
      );

      final decrypted = await algorithm.decrypt(secretBox, secretKey: secretKey);
      final jsonMap = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;

      return ScannedGuest(
        qrToken: jsonMap['t'] as String,
        name: jsonMap['n'] as String,
        phone: jsonMap['p'] as String,
        eventId: jsonMap['e'] as String,
        contributionAmount: jsonMap['a'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  static String _normalizeBase64Url(String input) {
    final remainder = input.length % 4;
    if (remainder == 0) return input;
    return input.padRight(input.length + (4 - remainder), '=');
  }
}
