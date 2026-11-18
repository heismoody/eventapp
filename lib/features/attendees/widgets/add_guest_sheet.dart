import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/category_picker_sheet.dart';
import '../../../shared/widgets/guest_category_field.dart';
import '../../../shared/widgets/people_field.dart';
import '../../../shared/widgets/tanzania_phone_field.dart';
import '../../contributions/models/contribution_models.dart';
import '../../contributions/services/contribution_service.dart';
import '../services/attendee_service.dart';
import '../../../l10n/l10n.dart';

/// What's typed so far, kept while the sheet steps aside for the
/// category picker, so nothing has to be typed twice.
class _GuestDraft {
  const _GuestDraft({
    this.name = '',
    this.phone = '',
    this.people = '',
    this.categoryId,
  });

  final String name;
  final String phone;
  final String people;
  final String? categoryId;

  _GuestDraft withCategory(String? id) =>
      _GuestDraft(name: name, phone: phone, people: people, categoryId: id);
}

/// How the sheet closed: saved, or stepping aside to pick a category.
class _SheetResult {
  const _SheetResult.saved() : draft = null;
  const _SheetResult.pick(this.draft);

  final _GuestDraft? draft;
}

/// Lets the owner add one guest by hand (name + phone), as an alternative to
/// picking them from the phone's contacts.
///
/// Choosing a category hands over instead of stacking sheets: this sheet
/// slides down, the category picker slides up, and once one is chosen this
/// sheet comes back with everything typed still in it.
Future<bool?> showAddGuestSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
}) async {
  var draft = const _GuestDraft();
  while (true) {
    if (!context.mounted) return null;
    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddGuestSheet(eventId: eventId, draft: draft),
    );
    if (result == null) return null;
    final picking = result.draft;
    if (picking == null) return true;
    draft = picking;

    await Future<void>.delayed(sheetHandOff);
    if (!context.mounted) return null;
    final choice = await showCategoryPickerSheet(
      context: context,
      eventId: eventId,
      selectedId: draft.categoryId,
    );
    if (choice != null) draft = draft.withCategory(choice.id);
    await Future<void>.delayed(sheetHandOff);
  }
}

class _AddGuestSheet extends ConsumerStatefulWidget {
  const _AddGuestSheet({required this.eventId, required this.draft});

  final String eventId;
  final _GuestDraft draft;

  @override
  ConsumerState<_AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends ConsumerState<_AddGuestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.draft.name);
  late final _phoneController = TextEditingController(text: widget.draft.phone);
  late final _peopleController = TextEditingController(
    text: widget.draft.people,
  );
  late String? _selectedCategoryId = widget.draft.categoryId;
  final _nameFocus = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Bring the keyboard up once the sheet has finished sliding in, not
    // during it: the two moving at once is what looks jerky. Back from the
    // category picker, the keyboard stays down.
    if (widget.draft.name.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final animation = ModalRoute.of(context)?.animation;
        void focus() {
          if (mounted) _nameFocus.requestFocus();
        }

        if (animation == null || animation.isCompleted) {
          focus();
          return;
        }
        void listener(AnimationStatus status) {
          if (status != AnimationStatus.completed) return;
          animation.removeStatusListener(listener);
          focus();
        }

        animation.addStatusListener(listener);
      });
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  _GuestDraft get _draft => _GuestDraft(
    name: _nameController.text,
    phone: _phoneController.text,
    people: _peopleController.text,
    categoryId: _selectedCategoryId,
  );

  /// Step aside for the category picker. showAddGuestSheet brings this
  /// sheet back afterwards.
  void _stepAside() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context, _SheetResult.pick(_draft));
  }

  int _typeDefault(List<ContributionCategory>? categories) =>
      categories
          ?.where((c) => c.id == _selectedCategoryId)
          .firstOrNull
          ?.defaultAdmits ??
      1;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(attendeeServiceProvider)
          .addGuest(
            eventId: widget.eventId,
            name: _nameController.text.trim(),
            phone: TanzaniaPhoneField.normalize(_phoneController.text),
            categoryId: _selectedCategoryId,
            admits: int.tryParse(_peopleController.text.trim()),
          );
      if (mounted) {
        Navigator.pop(context, const _SheetResult.saved());
        AppToast.success(appL10n.guestAdded);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(apiErrorMessage(e, context.l10n.addGuestFailed));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(
      contributionCategoriesProvider(widget.eventId),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                context.l10n.addGuest,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.addGuestLead,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_busy,
                focusNode: _nameFocus,
                decoration: InputDecoration(
                  labelText: context.l10n.name,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.nameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TanzaniaPhoneField(
                controller: _phoneController,
                enabled: !_busy,
                onFieldSubmitted: (_) => _busy ? null : _save(),
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => GuestCategoryField(
                  categories: const [],
                  selectedCategoryId: _selectedCategoryId,
                  enabled: !_busy,
                  onPick: _stepAside,
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
                data: (categories) => GuestCategoryField(
                  categories: categories,
                  selectedCategoryId: _selectedCategoryId,
                  enabled: !_busy,
                  onPick: _stepAside,
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
              ),
              const SizedBox(height: 12),
              PeopleField(
                controller: _peopleController,
                enabled: !_busy,
                label: context.l10n.peopleOnCard,
                hint: '${_typeDefault(categoriesAsync.valueOrNull)}',
                helperText: context.l10n.leaveEmptyForDefault(
                  _typeDefault(categoriesAsync.valueOrNull),
                ),
              ),
              const SizedBox(height: 20),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(context.l10n.addGuest),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
