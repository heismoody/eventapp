import 'dart:convert';

class JwtUtils {
  /// Returns true if the token is expired or cannot be parsed.
  /// Uses a small buffer so we refresh slightly before the exact expiry time.
  static bool isExpired(
    String token, {
    Duration buffer = const Duration(minutes: 1),
  }) {
    final expiry = getExpiry(token);
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry.subtract(buffer));
  }

  static DateTime? getExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadJson = utf8.decode(
        base64Url.decode(_normalizeBase64Url(parts[1])),
      );
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      final exp = payload['exp'];

      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _normalizeBase64Url(String input) {
    final remainder = input.length % 4;
    if (remainder == 0) return input;
    return input.padRight(input.length + (4 - remainder), '=');
  }
}
