import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../models/event_report.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref);
});

class ReportService {
  ReportService(this._ref);

  final Ref _ref;

  Future<EventReport> fetchReport(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(ApiConfig.eventReportPath(eventId));
    final data = response.data as Map<String, dynamic>;
    return EventReport.fromJson(data['report'] as Map<String, dynamic>);
  }
}

final eventReportProvider = FutureProvider.family<EventReport, String>((
  ref,
  eventId,
) async {
  return ref.read(reportServiceProvider).fetchReport(eventId);
});
