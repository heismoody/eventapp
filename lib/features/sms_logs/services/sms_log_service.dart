import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../models/sms_log_model.dart';

final smsLogServiceProvider = Provider<SmsLogService>((ref) {
  return SmsLogService(ref);
});

class SmsLogService {
  SmsLogService(this._ref);

  final Ref _ref;

  Future<List<SmsLogModel>> fetchLogs(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.smsLogsPath,
      queryParameters: {'eventId': eventId},
    );
    final data = response.data as Map<String, dynamic>;
    final logs = data['logs'] as List<dynamic>;
    return logs.map((e) => SmsLogModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final smsLogsProvider = FutureProvider.family<List<SmsLogModel>, String>((ref, eventId) async {
  return ref.read(smsLogServiceProvider).fetchLogs(eventId);
});
