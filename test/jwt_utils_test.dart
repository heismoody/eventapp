import 'package:flutter_test/flutter_test.dart';
import 'package:eventapp/core/auth/jwt_utils.dart';

void main() {
  test('detects expired JWT from exp claim', () {
    // exp = 2000000000 -> year 2033, not expired
    const validPayload = 'eyJleHAiOjIwMDAwMDAwMDB9'; // {"exp":2000000000}
    const header = 'eyJhbGciOiJIUzI1NiJ9';
    const signature = 'sig';
    final token = '$header.$validPayload.$signature';

    expect(JwtUtils.isExpired(token), isFalse);
  });

  test('detects expired JWT in the past', () {
    // exp = 1000000000 -> year 2001, expired
    const expiredPayload = 'eyJleHAiOjEwMDAwMDAwMDB9'; // {"exp":1000000000}
    const header = 'eyJhbGciOiJIUzI1NiJ9';
    const signature = 'sig';
    final token = '$header.$expiredPayload.$signature';

    expect(JwtUtils.isExpired(token), isTrue);
  });
}
