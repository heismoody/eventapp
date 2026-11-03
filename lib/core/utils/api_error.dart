import 'package:dio/dio.dart';

/// The server's own error text (`{"error": "..."}`) when it sent one, so the
/// user sees why a save was refused; otherwise [fallback].
String apiErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  if (error is StateError) return error.message;
  return fallback;
}
