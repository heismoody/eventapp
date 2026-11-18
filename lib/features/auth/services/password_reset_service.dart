import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Where the code went.
enum ResetChannel { sms, email }

class ResetCodeSent {
  const ResetCodeSent({
    required this.channel,
    required this.resendAfter,
    this.sentTo,
  });

  final ResetChannel channel;
  final Duration resendAfter;

  /// Masked by the portal ("•••456"), for a new customer's first password.
  final String? sentTo;
}

class ResetVerified {
  const ResetVerified({
    required this.resetToken,
    required this.name,
    this.signInWith,
  });

  /// Good for one new password, for 15 minutes.
  final String resetToken;
  final String name;

  /// For a new customer's first password: the phone (or email) on their
  /// account, to fill in the sign-in sheet. Only given after a right code.
  final String? signInWith;
}

class PasswordResetException implements Exception {
  PasswordResetException(this.message, {this.retryAfter});

  final String message;

  /// Set when the server says to wait before asking for another code.
  final Duration? retryAfter;

  @override
  String toString() => message;
}

final passwordResetServiceProvider = Provider<PasswordResetService>(
  PasswordResetService.new,
);

/// "Forgot password": a 6-digit code by SMS or email, then a new password.
/// The portal sends the SMS and email. The app never talks to those
/// services itself.
class PasswordResetService {
  PasswordResetService(this._ref);

  final Ref _ref;

  String get _base =>
      AppEnvironment.baseUrl(_ref.read(sharedPreferencesProvider));

  Dio get _dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<ResetCodeSent> requestCode(String identifier) async {
    final data = await _post(ApiConfig.resetCodePath, {
      'identifier': identifier,
    });
    return ResetCodeSent(
      channel: data['channel'] == 'email'
          ? ResetChannel.email
          : ResetChannel.sms,
      resendAfter: Duration(
        seconds: (data['resendAfterSeconds'] as num?)?.toInt() ?? 60,
      ),
    );
  }

  /// A new customer's first password: the portal sends the code to the
  /// phone or email on the account it made for [requestId].
  Future<ResetCodeSent> requestCodeForRequest(
    String requestId,
    ResetChannel channel,
  ) async {
    final data = await _post(ApiConfig.requestCodePath(requestId), {
      'channel': channel == ResetChannel.email ? 'email' : 'sms',
    });
    return ResetCodeSent(
      channel: channel,
      sentTo: data['sentTo'] as String?,
      resendAfter: Duration(
        seconds: (data['resendAfterSeconds'] as num?)?.toInt() ?? 60,
      ),
    );
  }

  Future<ResetVerified> verifyCodeForRequest(
    String requestId,
    ResetChannel channel,
    String code,
  ) async {
    final data = await _post(ApiConfig.resetVerifyPath, {
      'eventRequestId': requestId,
      'channel': channel == ResetChannel.email ? 'email' : 'sms',
      'code': code,
    });
    return ResetVerified(
      resetToken: data['resetToken'] as String,
      name: data['name'] as String? ?? '',
      signInWith: data['signInWith'] as String?,
    );
  }

  Future<ResetVerified> verifyCode(String identifier, String code) async {
    final data = await _post(ApiConfig.resetVerifyPath, {
      'identifier': identifier,
      'code': code,
    });
    return ResetVerified(
      resetToken: data['resetToken'] as String,
      name: data['name'] as String? ?? '',
    );
  }

  /// Saves the new password. The portal signs the person in, so this
  /// stores that session like a normal sign-in does.
  Future<UserModel> complete(String resetToken, String newPassword) async {
    final data = await _post(ApiConfig.resetCompletePath, {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
    return _ref.read(authServiceProvider).storeSession(data);
  }

  /// A new customer's first password. Only saves it: they then sign in
  /// on the sign-in sheet like everyone else.
  Future<void> choose(String resetToken, String newPassword) async {
    await _post(ApiConfig.resetCompletePath, {
      'resetToken': resetToken,
      'newPassword': newPassword,
      'signIn': false,
    });
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = '$_base$path';
    try {
      final response = await _dio.post(url, data: body);
      debugPrint('[password-reset] POST $path -> ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      debugPrint(
        '[password-reset] POST $path failed: ${error.type.name} '
        '${error.response?.statusCode ?? ''} ${error.response?.data ?? error.message ?? ''}',
      );
      final explained = _explain(error);
      if (AppEnvironment.isProd) throw explained;
      throw PasswordResetException(
        '${explained.message}\n[dev] ${error.response?.statusCode ?? error.type.name} from $url',
        retryAfter: explained.retryAfter,
      );
    }
  }

  PasswordResetException _explain(DioException error) {
    final data = error.response?.data;
    final serverMessage = data is Map ? data['error'] as String? : null;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return PasswordResetException(
          "Can't reach Cardly. Check your internet connection and try again.",
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 404 && serverMessage == null) {
          // An older server without this address (a page, not JSON).
          return PasswordResetException(
            "Password reset isn't available yet. WhatsApp us and we'll help.",
          );
        }
        final retry = data is Map ? data['retryAfterSeconds'] : null;
        return PasswordResetException(
          serverMessage ?? 'Something went wrong. Please try again.',
          retryAfter: retry is num ? Duration(seconds: retry.toInt()) : null,
        );
      default:
        return PasswordResetException(
          'Something went wrong. Please try again.',
        );
    }
  }
}
