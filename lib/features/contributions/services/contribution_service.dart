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
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post(
      ApiConfig.contributionCategoriesPath,
      data: {'eventId': eventId, 'name': name},
    );
    final data = response.data as Map<String, dynamic>;
    return ContributionCategory.fromJson(
      data['category'] as Map<String, dynamic>,
    );
  }

  Future<ContributionCategory> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.patch(
      ApiConfig.contributionCategoryPath(categoryId),
      data: {'name': name},
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

  /// Sets what a guest has pledged to contribute — distinct from a payment:
  /// this is the target, not money actually received.
  Future<void> setPledge({
    required String attendeeId,
    required double pledgeAmount,
  }) async {
    final dio = _ref.read(apiClientProvider);
    await dio.patch(
      ApiConfig.attendeePatchPath(attendeeId),
      data: {'pledgeAmount': pledgeAmount},
    );
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

  Future<List<ContributionRecord>> fetchContributions(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.contributionsPath,
      queryParameters: {'eventId': eventId},
    );
    final data = response.data as Map<String, dynamic>;
    final rows = data['contributions'] as List<dynamic>? ?? [];
    return rows
        .map(
          (item) => ContributionRecord.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}

final contributionCategoriesProvider =
    FutureProvider.family<List<ContributionCategory>, String>((
      ref,
      eventId,
    ) async {
      return ref.read(contributionServiceProvider).fetchCategories(eventId);
    });

final contributionsProvider =
    FutureProvider.family<List<ContributionRecord>, String>((
      ref,
      eventId,
    ) async {
      return ref.read(contributionServiceProvider).fetchContributions(eventId);
    });
