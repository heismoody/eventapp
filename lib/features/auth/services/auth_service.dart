import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

class AuthService {
  AuthService(this._ref);

  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  /// Signs in with an email or a phone number.
  Future<UserModel> login(String identifier, String password) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final prefs = _ref.read(sharedPreferencesProvider);
    final baseUrl = AppEnvironment.baseUrl(prefs);

    final response = await dio.post(
      '$baseUrl${ApiConfig.authPath}',
      // `email` too, for servers from before phone sign-in, which only
      // read that field.
      data: {
        'identifier': identifier,
        'email': identifier,
        'password': password,
      },
    );

    return storeSession(response.data as Map<String, dynamic>);
  }

  /// Saves the token and user from a sign-in response (`{token, user}`).
  Future<UserModel> storeSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

    return user;
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<UserModel?> getStoredUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
