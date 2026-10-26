import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_toast.dart';
import '../../../core/constants/app_colors.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';

Future<ContributionCategory?> showContributionCategorySheet({
  required BuildContext context,
  required String eventId,
  ContributionCategory? category,
}) {
  return showModalBottomSheet<ContributionCategory>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) =>
        _ContributionCategorySheet(eventId: eventId, category: category),
  );
}

class _ContributionCategorySheet extends ConsumerStatefulWidget {
  const _ContributionCategorySheet({required this.eventId, this.category});

  final String eventId;
  final ContributionCategory? category;

  @override
  ConsumerState<_ContributionCategorySheet> createState() =>
      _ContributionCategorySheetState();
}

class _ContributionCategorySheetState
    extends ConsumerState<_ContributionCategorySheet> {
  late final TextEditingController _nameController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitting = true);
    try {
      final service = ref.read(contributionServiceProvider);
      final ContributionCategory saved;
      if (widget.category == null) {
        saved = await service.createCategory(
          eventId: widget.eventId,
          name: _nameController.text.trim(),
        );
      } else {
        saved = await service.updateCategory(
          categoryId: widget.category!.id,
          name: _nameController.text.trim(),
        );
      }
      ref.invalidate(contributionCategoriesProvider(widget.eventId));
      if (mounted) {
        AppToast.success(
          widget.category == null ? 'Category saved' : 'Category updated',
        );
        Navigator.pop(context, saved);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        AppToast.error('Failed to save category');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            Text(
              widget.category == null ? 'Add category' : 'Edit category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: !_submitting,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _save,
                child: Text(_submitting ? 'Saving...' : 'Save category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
