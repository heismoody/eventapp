import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/contributions/models/contribution_models.dart';

const _fieldHeight = 58.0;

/// An optional category picker, reused everywhere a guest can be tagged
/// with a contribution category — editing one guest, adding one by hand, or
/// importing several at once. Some event owners group guests this way,
/// others never set up categories at all, so this is always skippable.
class GuestCategoryField extends StatelessWidget {
  const GuestCategoryField({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
    required this.onAddCategory,
    this.enabled = true,
    this.label = 'Category (optional)',
  });

  final List<ContributionCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddCategory;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _fieldHeight,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selectedCategoryId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No category'),
                    ),
                    ...categories.map(
                      (category) => DropdownMenuItem<String?>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                    // A just-created category can be selected before the
                    // categories list has refetched to include it — keep
                    // the dropdown's value valid until it catches up.
                    if (selectedCategoryId != null &&
                        !categories.any((c) => c.id == selectedCategoryId))
                      DropdownMenuItem<String?>(
                        value: selectedCategoryId,
                        child: const Text('Selected category'),
                      ),
                  ],
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: enabled ? onAddCategory : null,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 46,
              height: _fieldHeight,
              child: Icon(Icons.add, color: AppColors.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
