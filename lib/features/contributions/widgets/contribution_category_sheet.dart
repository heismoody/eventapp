import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/api_error.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/people_field.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';
import '../../attendees/services/attendee_service.dart';
import '../../../l10n/l10n.dart';

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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _peopleController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _peopleController = TextEditingController(
      text: '${widget.category?.defaultAdmits ?? 1}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  /// When an existing type's default changes, asks whether its cards still
  /// on the old number follow. Null means the user backed out.
  Future<bool?> _askApplyToCards(int from, int to) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.updateExistingCardsTitle),
        content: Text(context.l10n.updateExistingCardsBody(from, to)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.onlyNewCards),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.updateCards),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.error(context.l10n.enterCategoryName);
      return;
    }
    final people = int.parse(_peopleController.text.trim());
    final existing = widget.category;

    var applyToCards = false;
    if (existing != null && people != existing.defaultAdmits) {
      final choice = await _askApplyToCards(existing.defaultAdmits, people);
      if (choice == null) return;
      applyToCards = choice;
    }

    setState(() => _submitting = true);
    try {
      final service = ref.read(contributionServiceProvider);
      final ContributionCategory saved;
      var cardsUpdated = 0;
      if (existing == null) {
        saved = await service.createCategory(
          eventId: widget.eventId,
          name: name,
          defaultAdmits: people,
        );
      } else {
        final result = await service.updateCategory(
          categoryId: existing.id,
          name: name,
          defaultAdmits: people,
          applyToCards: applyToCards,
        );
        saved = result.category;
        cardsUpdated = result.cardsUpdated;
      }
      ref.invalidate(contributionCategoriesProvider(widget.eventId));
      if (cardsUpdated > 0) ref.invalidate(attendeesProvider(widget.eventId));
      if (mounted) {
        AppToast.success(
          existing == null
              ? context.l10n.categorySaved
              : cardsUpdated > 0
              ? context.l10n.categoryUpdatedCards(cardsUpdated, people)
              : context.l10n.categoryUpdated,
        );
        Navigator.pop(context, saved);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        AppToast.error(apiErrorMessage(error, context.l10n.saveCategoryFailed));
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
              widget.category == null
                  ? context.l10n.addCategory
                  : context.l10n.editCategory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: !_submitting,
              decoration: InputDecoration(labelText: context.l10n.categoryName),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: PeopleField(
                controller: _peopleController,
                enabled: !_submitting,
                label: context.l10n.peoplePerCardLabel,
                helperText: context.l10n.peoplePerCardHelper,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _save,
                child: Text(
                  _submitting ? context.l10n.saving : context.l10n.saveCategory,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
