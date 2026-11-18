import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../features/contributions/models/contribution_models.dart';
import '../../features/contributions/services/contribution_service.dart';
import '../../features/contributions/widgets/contribution_category_sheet.dart';
import '../../l10n/l10n.dart';

/// A bottom sheet's slide-down, so the next one waits for it to finish
/// instead of stacking on top.
const sheetHandOff = Duration(milliseconds: 240);

/// The category chosen in [showCategoryPickerSheet]. [id] null means
/// "No category".
class CategoryChoice {
  const CategoryChoice(this.id);

  final String? id;
}

/// Picks a guest category in its own sheet. Returns null when dismissed
/// (keep what was chosen before). "New category" hands over to the create
/// sheet and, once saved, returns the new one already chosen.
///
/// Open it after closing the sheet it was picked from (see
/// [sheetHandOff]), so only one sheet is ever on screen.
Future<CategoryChoice?> showCategoryPickerSheet({
  required BuildContext context,
  required String eventId,
  required String? selectedId,
}) async {
  while (true) {
    if (!context.mounted) return null;
    final picked = await showModalBottomSheet<_PickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          _CategoryPicker(eventId: eventId, selectedId: selectedId),
    );
    if (picked == null) return null;
    if (picked.choice != null) return picked.choice;

    // "New category": hand over to the create sheet.
    await Future<void>.delayed(sheetHandOff);
    if (!context.mounted) return null;
    final created = await showContributionCategorySheet(
      context: context,
      eventId: eventId,
    );
    if (!context.mounted) return null;
    ProviderScope.containerOf(
      context,
      listen: false,
    ).invalidate(contributionCategoriesProvider(eventId));
    if (created != null) return CategoryChoice(created.id);
    // Closed without saving: back to the list.
    await Future<void>.delayed(sheetHandOff);
  }
}

/// A choice, or (choice null) a request for "New category".
class _PickerResult {
  const _PickerResult(this.choice);

  final CategoryChoice? choice;
}

class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({required this.eventId, required this.selectedId});

  final String eventId;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(contributionCategoriesProvider(eventId));

    void choose(String? id) =>
        Navigator.pop(context, _PickerResult(CategoryChoice(id)));

    Widget option({
      required String? id,
      required String title,
      String? subtitle,
    }) {
      final selected = id == selectedId;
      return Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => choose(id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chooseCategoryTitle,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.chooseCategoryLead,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: categoriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => ListView(
                shrinkWrap: true,
                children: [option(id: null, title: l10n.dashNoCategory)],
              ),
              data: (List<ContributionCategory> categories) => ListView(
                shrinkWrap: true,
                children: [
                  option(id: null, title: l10n.dashNoCategory),
                  for (final c in categories)
                    option(
                      id: c.id,
                      title: c.name,
                      subtitle: l10n.admitsPeople(c.defaultAdmits),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, const _PickerResult(null)),
            icon: const Icon(Icons.add),
            label: Text(l10n.newCategoryButton),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
