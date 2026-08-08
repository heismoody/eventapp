import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../models/contribution_models.dart';

final contributionServiceProvider = Provider<ContributionService>((ref) {
  return ContributionService(ref);
});

class ContributionService {
  ContributionService(this._ref);

  final Ref _ref;

  Future<List<ContributionCategory>> fetchCategories(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.contributionCategoriesPath,
      queryParameters: {'eventId': eventId},
    );
    final data = response.data as Map<String, dynamic>;
    final categories = data['categories'] as List<dynamic>;
    return categories
        .map(
          (item) => ContributionCategory.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ContributionCategory> createCategory({
    required String eventId,
    required String name,
    required String targetAmount,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post(
      ApiConfig.contributionCategoriesPath,
      data: {'eventId': eventId, 'name': name, 'targetAmount': targetAmount},
    );
    final data = response.data as Map<String, dynamic>;
    return ContributionCategory.fromJson(
      data['category'] as Map<String, dynamic>,
    );
  }

  Future<ContributionCategory> updateCategory({
    required String categoryId,
    required String name,
    required String targetAmount,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.patch(
      ApiConfig.contributionCategoryPath(categoryId),
      data: {'name': name, 'targetAmount': targetAmount},
    );
    final data = response.data as Map<String, dynamic>;
    return ContributionCategory.fromJson(
      data['category'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final dio = _ref.read(apiClientProvider);
    await dio.delete(ApiConfig.contributionCategoryPath(categoryId));
  }

  Future<AttendeeContributionUpdate> recordPayment({
    required String attendeeId,
    required double paymentReceived,
    String? categoryId,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.patch(
      ApiConfig.attendeePatchPath(attendeeId),
      data: {
        if (categoryId != null) 'categoryId': categoryId,
        'paymentReceived': paymentReceived,
      },
    );
    return AttendeeContributionUpdate.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<AttendeeContributionUpdate> assignCategory({
    required String attendeeId,
    required String categoryId,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.patch(
      ApiConfig.attendeePatchPath(attendeeId),
      data: {'categoryId': categoryId},
    );
    return AttendeeContributionUpdate.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<SmsSendResult> sendSmsBroadcast({
    required String eventId,
    required String template,
    List<String>? attendeeIds,
  }) async {
    final dio = _ref.read(apiClientProvider);
    try {
      final response = await dio.post(
        ApiConfig.smsBroadcastPath,
        data: {
          'eventId': eventId,
          'template': template,
          if (attendeeIds != null) 'attendeeIds': attendeeIds,
        },
      );
      return SmsSendResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return SmsSendResult.fromJson(data);
        }
      }
      rethrow;
    }
  }

  Future<SmsSendResult> sendContributionSms({
    required String eventId,
    required String type,
    List<String>? attendeeIds,
  }) async {
    final dio = _ref.read(apiClientProvider);
    try {
      final response = await dio.post(
        ApiConfig.smsReminderPath,
        data: {
          'eventId': eventId,
          'type': type,
          if (attendeeIds != null) 'attendeeIds': attendeeIds,
        },
      );
      return SmsSendResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return SmsSendResult.fromJson(data);
        }
      }
      rethrow;
    }
  }

  Future<SmsBillingSummary> fetchBilling(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.smsBillingPath,
      queryParameters: {'eventId': eventId},
    );
    return SmsBillingSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SmsCreditsSummary> fetchCredits(
    String eventId, {
    int? required,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.smsCreditsPath,
      queryParameters: {
        'eventId': eventId,
        if (required != null) 'required': required,
      },
    );
    return SmsCreditsSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SmsLogRecord>> fetchSmsLogs(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.smsLogsPath,
      queryParameters: {'eventId': eventId},
    );
    final data = response.data as Map<String, dynamic>;
    final logs = data['logs'] as List<dynamic>? ?? [];
    return logs
        .map((item) => SmsLogRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentSubmissionRecord>> fetchPaymentSubmissions(
    String eventId,
  ) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.smsPaymentsPath,
      queryParameters: {'eventId': eventId},
    );
    final data = response.data as Map<String, dynamic>;
    final submissions = data['submissions'] as List<dynamic>? ?? [];
    return submissions
        .map(
          (item) =>
              PaymentSubmissionRecord.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<PaymentSubmitResult> submitPaymentWithProof({
    required String eventId,
    required int amountTzs,
    required String filePath,
    required String fileName,
    String? notes,
  }) async {
    final dio = _ref.read(apiClientProvider);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'eventId': eventId,
        'amountTzs': amountTzs,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      final response = await dio.post(
        ApiConfig.smsPaymentsPath,
        data: formData,
      );
      return PaymentSubmitResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      rethrow;
    }
  }

  Future<List<SmsTemplate>> fetchSmsTemplates(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.smsTemplatesPath,
      queryParameters: {'eventId': eventId},
    );
    final data = response.data as Map<String, dynamic>;
    final templates = data['templates'] as List<dynamic>? ?? [];
    return templates
        .map((item) => SmsTemplate.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SmsTemplate> createSmsTemplate({
    required String eventId,
    required String name,
    required String body,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post(
      ApiConfig.smsTemplatesPath,
      data: {'eventId': eventId, 'name': name, 'body': body},
    );
    final data = response.data as Map<String, dynamic>;
    return SmsTemplate.fromJson(data['template'] as Map<String, dynamic>);
  }

  Future<SmsTemplate> updateSmsTemplate({
    required String templateId,
    required String name,
    required String body,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.patch(
      ApiConfig.smsTemplatePath(templateId),
      data: {'name': name, 'body': body},
    );
    final data = response.data as Map<String, dynamic>;
    return SmsTemplate.fromJson(data['template'] as Map<String, dynamic>);
  }

  Future<void> deleteSmsTemplate(String templateId) async {
    final dio = _ref.read(apiClientProvider);
    await dio.delete(ApiConfig.smsTemplatePath(templateId));
  }
}

final contributionCategoriesProvider =
    FutureProvider.family<List<ContributionCategory>, String>((
      ref,
      eventId,
    ) async {
      return ref.read(contributionServiceProvider).fetchCategories(eventId);
    });

final smsBillingProvider = FutureProvider.family<SmsBillingSummary, String>((
  ref,
  eventId,
) async {
  return ref.read(contributionServiceProvider).fetchBilling(eventId);
});

final smsCreditsProvider = FutureProvider.family<SmsCreditsSummary, String>((
  ref,
  eventId,
) async {
  return ref.read(contributionServiceProvider).fetchCredits(eventId);
});

final smsLogsProvider = FutureProvider.family<List<SmsLogRecord>, String>((
  ref,
  eventId,
) async {
  return ref.read(contributionServiceProvider).fetchSmsLogs(eventId);
});

final smsPaymentsProvider =
    FutureProvider.family<List<PaymentSubmissionRecord>, String>((
  ref,
  eventId,
) async {
  return ref.read(contributionServiceProvider).fetchPaymentSubmissions(eventId);
});

final smsTemplatesProvider = FutureProvider.family<List<SmsTemplate>, String>((
  ref,
  eventId,
) async {
  return ref.read(contributionServiceProvider).fetchSmsTemplates(eventId);
});
