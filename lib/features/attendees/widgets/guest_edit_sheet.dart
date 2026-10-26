import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/guest_category_field.dart';
import '../../../shared/widgets/tanzania_phone_field.dart';
import '../../contributions/models/contribution_models.dart';
import '../../contributions/services/contribution_service.dart';
import '../../contributions/widgets/contribution_category_sheet.dart';
import '../../events/providers/event_provider.dart';
import '../services/attendee_service.dart';

Future<void> showGuestEditSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AttendeeRecord attendee,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _GuestEditSheet(attendee: attendee),
  );
}

class _GuestEditSheet extends ConsumerStatefulWidget {
  const _GuestEditSheet({required this.attendee});

  final AttendeeRecord attendee;

  @override
  ConsumerState<_GuestEditSheet> createState() => _GuestEditSheetState();
}

class _GuestEditSheetState extends ConsumerState<_GuestEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _amountController;
  late final TextEditingController _pledgeController;
  String? _selectedCategoryId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.attendee.name);
    _phoneController = TextEditingController(
      text: TanzaniaPhoneField.localPartOf(widget.attendee.phone),
    );
    _amountController = TextEditingController(
      text: widget.attendee.paidAmount > 0
          ? widget.attendee.paidAmount.toStringAsFixed(0)
          : '',
    );
    _pledgeController = TextEditingController(
      text: widget.attendee.targetAmountValue > 0
          ? widget.attendee.targetAmountValue.toStringAsFixed(0)
          : '',
    );
    _selectedCategoryId = widget.attendee.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _pledgeController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  Future<void> _openAddCategory(String eventId) async {
    final created = await showContributionCategorySheet(
      context: context,
      eventId: eventId,
    );
    if (created != null && mounted) {
      setState(() => _selectedCategoryId = created.id);
    }
  }

  Future<void> _save(String eventId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final amountText = _amountController.text.trim();
      await ref
          .read(attendeeServiceProvider)
          .updateAttendee(
            attendeeId: widget.attendee.id,
            name: _nameController.text.trim(),
            phone: TanzaniaPhoneField.normalize(_phoneController.text),
            categoryId: _selectedCategoryId,
            contributionAmount: amountText.isEmpty ? '0' : amountText,
            pledgeAmount: _pledgeController.text.trim(),
          );
      ref.invalidate(attendeesProvider(eventId));
      if (mounted) {
        Navigator.pop(context);
        AppToast.success('Guest updated');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error('Failed to update guest');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildCategoryField(
    String eventId,
    List<ContributionCategory> categories,
  ) {
    return GuestCategoryField(
      categories: categories,
      selectedCategoryId: _selectedCategoryId,
      enabled: !_busy,
      label: 'Contribution category',
      onAddCategory: () => _openAddCategory(eventId),
      onChanged: (value) => setState(() => _selectedCategoryId = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);
    final categoriesAsync = eventId != null
        ? ref.watch(contributionCategoriesProvider(eventId))
        : const AsyncValue.data(<ContributionCategory>[]);

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
              Text('Edit guest', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_busy,
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
              TanzaniaPhoneField(controller: _phoneController, enabled: !_busy),
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => _buildCategoryField(eventId ?? '', const []),
                data: (categories) =>
                    _buildCategoryField(eventId ?? '', categories),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: 'Amount paid (TZS)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: _validateAmount,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pledgeController,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: 'Pledge (TZS, optional)',
                  helperText: 'What this guest has promised to contribute',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: _validateAmount,
              ),
              const SizedBox(height: 20),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: eventId == null ? null : () => _save(eventId),
                    child: const Text('Save changes'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
