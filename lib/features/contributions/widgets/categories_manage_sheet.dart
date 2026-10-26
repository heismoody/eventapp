import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';
import 'contribution_category_sheet.dart';

Future<void> showCategoriesManageSheet({
  required BuildContext context,
  required String eventId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _CategoriesManageSheet(eventId: eventId),
  );
}

class _CategoriesManageSheet extends ConsumerWidget {
  const _CategoriesManageSheet({required this.eventId});

  final String eventId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    await showContributionCategorySheet(context: context, eventId: eventId);
    ref.invalidate(contributionCategoriesProvider(eventId));
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ContributionCategory category,
  ) async {
    await showContributionCategorySheet(
      context: context,
      eventId: eventId,
      category: category,
    );
    ref.invalidate(contributionCategoriesProvider(eventId));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ContributionCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text(
          'Guests in this category will be left without a category. '
          'Their pledges and payments are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(contributionServiceProvider).deleteCategory(category.id);
      ref.invalidate(contributionCategoriesProvider(eventId));
    } catch (_) {
      AppToast.error('Failed to delete category');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(contributionCategoriesProvider(eventId));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Tooltip(
                message: 'Add category',
                child: IconButton.filled(
                  onPressed: () => _add(context, ref),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: categoriesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load categories.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No categories yet. Use the + button to create one.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => _edit(context, ref, category),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => _delete(context, ref, category),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
