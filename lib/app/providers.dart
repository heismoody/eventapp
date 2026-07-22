import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_config.dart';
import '../../core/auth/jwt_utils.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/services/session_manager.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// ─── Pretty logger ──────────────────────────────────────────────────────────

const _logTag = 'EventSys';
const _forceApiLogs = bool.fromEnvironment('API_LOGS', defaultValue: false);

bool get _apiLoggingEnabled => !kReleaseMode || _forceApiLogs;

void _log(String message) {
  if (!_apiLoggingEnabled) return;
  // print() is more reliable than debugPrint in the flutter run terminal.
  print('[$_logTag] $message');
}

class _PrettyLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('\n┌──── REQUEST ────────────────────────────────────────────');
    _log('│ ${options.method.toUpperCase()}  ${options.uri}');
    if (options.headers['Authorization'] != null) {
      final auth = options.headers['Authorization'] as String;
      _log('│ Auth: ${auth.length > 20 ? '${auth.substring(0, 20)}…' : auth}');
    }
    if (options.queryParameters.isNotEmpty) {
      _log('│ Query: ${options.queryParameters}');
    }
    if (options.data != null) {
      _log('│ Body:  ${options.data}');
    }
    _log('└─────────────────────────────────────────────────────────');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final emoji = _statusEmoji(response.statusCode ?? 0);
    _log('\n┌──── RESPONSE ───────────────────────────────────────────');
    _log('│ $emoji ${response.statusCode}  ${response.requestOptions.uri}');
    _log('│ ${_summarise(response.data)}');
    _log('└─────────────────────────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log('\n┌──── ERROR ──────────────────────────────────────────────');
    _log('│ ❌ ${err.response?.statusCode ?? 'NO STATUS'}  ${err.requestOptions.uri}');
    _log('│ ${err.message}');
    if (err.response?.data != null) {
      _log('│ Body: ${_summarise(err.response!.data)}');
    }
    _log('└─────────────────────────────────────────────────────────');
    super.onError(err, handler);
  }

  String _statusEmoji(int code) {
    if (code >= 200 && code < 300) return '✅';
    if (code >= 400 && code < 500) return '⚠️ ';
    if (code >= 500) return '🔥';
    return '🔵';
  }

  String _summarise(dynamic data) {
    if (data == null) return '(empty)';
    final str = data.toString();
    return str.length > 300 ? '${str.substring(0, 300)}…' : str;
  }
}

// ────────────────────────────────────────────────────────────────────────────

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Auth + baseUrl injector + session expiry handling
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = ref.read(sharedPreferencesProvider);
        final baseUrl = prefs.getString(ApiConfig.baseUrlKey) ?? ApiConfig.defaultBaseUrl;
        options.baseUrl = baseUrl;

        final token = ref.read(authTokenProvider);
        if (token != null && token.isNotEmpty) {
          if (JwtUtils.isExpired(token)) {
            await ref.read(sessionManagerProvider).handleSessionExpired();
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                message: 'Session expired',
              ),
            );
            return;
          }
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final path = error.requestOptions.path;

        if (statusCode == 401 && !path.contains(ApiConfig.authPath)) {
          await ref.read(sessionManagerProvider).handleSessionExpired();
        }

        handler.next(error);
      },
    ),
  );

  // Pretty request / response logger (debug/profile, or API_LOGS=true)
  if (_apiLoggingEnabled) {
    dio.interceptors.add(_PrettyLogInterceptor());
  }

  return dio;
});
