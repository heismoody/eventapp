import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/providers.dart';
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

  Future<UserModel> login(String email, String password) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final prefs = _ref.read(sharedPreferencesProvider);
    final baseUrl = prefs.getString(ApiConfig.baseUrlKey) ?? ApiConfig.defaultBaseUrl;

    final response = await dio.post(
      '$baseUrl${ApiConfig.authPath}',
      data: {'email': email, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: user.email);

    return user;
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
