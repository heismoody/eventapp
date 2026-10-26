import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_toast.dart';
import '../../../core/constants/app_colors.dart';
import '../../events/providers/event_provider.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';
import '../widgets/contribution_category_sheet.dart';

class ContributionCategoriesScreen extends ConsumerStatefulWidget {
  const ContributionCategoriesScreen({super.key});

  @override
  ConsumerState<ContributionCategoriesScreen> createState() =>
      _ContributionCategoriesScreenState();
}

class _ContributionCategoriesScreenState
    extends ConsumerState<ContributionCategoriesScreen> {
  Future<void> _refresh(String eventId) async {
    ref.invalidate(contributionCategoriesProvider(eventId));
    await ref.read(contributionCategoriesProvider(eventId).future);
  }

  Future<void> _showCategorySheet({
    required String eventId,
    ContributionCategory? category,
  }) async {
    await showContributionCategorySheet(
      context: context,
      eventId: eventId,
      category: category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);
    if (eventId == null) {
      return const Scaffold(body: Center(child: Text('Select an event first')));
    }

    final categoriesAsync = ref.watch(contributionCategoriesProvider(eventId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Contribution categories',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategorySheet(eventId: eventId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: OutlinedButton(
            onPressed: () => _refresh(eventId),
            child: const Text('Try again'),
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refresh(eventId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No categories yet.\nTap + to add Single, Double, Family, etc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(eventId),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _showCategorySheet(
                          eventId: eventId,
                          category: category,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () async {
                          try {
                            await ref
                                .read(contributionServiceProvider)
                                .deleteCategory(category.id);
                            ref.invalidate(
                              contributionCategoriesProvider(eventId),
                            );
                          } catch (_) {
                            if (context.mounted) {
                              AppToast.error('Failed to delete category');
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
