import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';
import 'contribution_category_sheet.dart';
import '../../../l10n/l10n.dart';

/// What the list sheet asks for when it closes: add a category, or edit
/// [category]. Null when it was just dismissed.
class _OpenCategory {
  const _OpenCategory([this.category]);

  final ContributionCategory? category;
}

/// A bottom sheet's slide-down, so the next one waits for it to finish.
const _handOff = Duration(milliseconds: 240);

/// The categories list. Adding or editing one hands over to its own sheet
/// instead of stacking on top: the list slides down, the category sheet
/// slides up, and after Save (or closing it) the list comes back, updated.
Future<void> showCategoriesManageSheet({
  required BuildContext context,
  required String eventId,
}) async {
  while (true) {
    if (!context.mounted) return;
    final next = await showModalBottomSheet<_OpenCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CategoriesManageSheet(eventId: eventId),
    );
    if (next == null || !context.mounted) return;

    await Future<void>.delayed(_handOff);
    if (!context.mounted) return;
    await showContributionCategorySheet(
      context: context,
      eventId: eventId,
      category: next.category,
    );
    if (!context.mounted) return;
    ProviderScope.containerOf(
      context,
      listen: false,
    ).invalidate(contributionCategoriesProvider(eventId));
    await Future<void>.delayed(_handOff);
  }
}

class _CategoriesManageSheet extends ConsumerWidget {
  const _CategoriesManageSheet({required this.eventId});

  final String eventId;

  // Close this sheet and let showCategoriesManageSheet open the category
  // sheet in its place.
  void _add(BuildContext context) =>
      Navigator.pop(context, const _OpenCategory());

  void _edit(BuildContext context, ContributionCategory category) =>
      Navigator.pop(context, _OpenCategory(category));

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ContributionCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteCategoryTitle(category.name)),
        content: Text(context.l10n.deleteCategoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(contributionServiceProvider).deleteCategory(category.id);
      ref.invalidate(contributionCategoriesProvider(eventId));
    } catch (_) {
      AppToast.error(appL10n.deleteCategoryFailed);
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
                  context.l10n.categories,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Tooltip(
                message: context.l10n.addCategory,
                child: IconButton.filled(
                  onPressed: () => _add(context),
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
              error: (_, _) => Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  context.l10n.loadCategoriesFailed,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      context.l10n.noCategoriesUsePlus,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        context.l10n.peoplePerCard(category.defaultAdmits),
                        style: TextStyle(color: AppColors.muted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: context.l10n.edit,
                            onPressed: () => _edit(context, category),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: context.l10n.delete,
                            onPressed: () => _delete(context, ref, category),
                            icon: Icon(
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
