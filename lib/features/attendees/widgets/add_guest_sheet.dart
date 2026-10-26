import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/guest_category_field.dart';
import '../../../shared/widgets/tanzania_phone_field.dart';
import '../../contributions/services/contribution_service.dart';
import '../../contributions/widgets/contribution_category_sheet.dart';
import '../services/attendee_service.dart';

/// Lets the owner add one guest by hand (name + phone), as an alternative to
/// picking them from the phone's contacts.
Future<bool?> showAddGuestSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _AddGuestSheet(eventId: eventId),
  );
}

class _AddGuestSheet extends ConsumerStatefulWidget {
  const _AddGuestSheet({required this.eventId});

  final String eventId;

  @override
  ConsumerState<_AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends ConsumerState<_AddGuestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCategoryId;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openAddCategory() async {
    final created = await showContributionCategorySheet(
      context: context,
      eventId: widget.eventId,
    );
    if (created != null && mounted) {
      setState(() => _selectedCategoryId = created.id);
    }
  }

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
          );
      if (mounted) {
        Navigator.pop(context, true);
        AppToast.success('Guest added');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          e is StateError
              ? e.message
              : 'Failed to add guest. Please try again.',
        );
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
              Text('Add guest', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text(
                'Enter their details by hand instead of picking from contacts.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_busy,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
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
                  onAddCategory: _openAddCategory,
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
                data: (categories) => GuestCategoryField(
                  categories: categories,
                  selectedCategoryId: _selectedCategoryId,
                  enabled: !_busy,
                  onAddCategory: _openAddCategory,
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
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
                    child: const Text('Add guest'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
