import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/guest_category_field.dart';
import '../../../shared/widgets/people_field.dart';
import '../../../shared/widgets/tanzania_phone_field.dart';
import '../../contributions/models/contribution_models.dart';
import '../../contributions/services/contribution_service.dart';
import '../../contributions/widgets/contribution_category_sheet.dart';
import '../../events/providers/event_provider.dart';
import '../services/attendee_service.dart';
import '../../../l10n/l10n.dart';

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
  late final TextEditingController _peopleController;
  late final List<_CompanionRow> _companions;
  bool _companionsChanged = false;
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
    _peopleController = TextEditingController(
      text: '${widget.attendee.admits}',
    );
    _companions = [
      for (final companion in widget.attendee.companions)
        _CompanionRow.from(companion),
    ];
    _selectedCategoryId = widget.attendee.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _pledgeController.dispose();
    _peopleController.dispose();
    for (final row in _companions) {
      row.dispose();
    }
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return context.l10n.enterValidAmount;
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
      final people = int.tryParse(_peopleController.text.trim());
      await ref
          .read(attendeeServiceProvider)
          .updateAttendee(
            attendeeId: widget.attendee.id,
            name: _nameController.text.trim(),
            phone: TanzaniaPhoneField.normalize(_phoneController.text),
            categoryId: _selectedCategoryId,
            contributionAmount: amountText.isEmpty ? '0' : amountText,
            pledgeAmount: _pledgeController.text.trim(),
            admits: people != widget.attendee.admits ? people : null,
          );
      if (_companionsChanged) await _saveCompanions();
      ref.invalidate(attendeesProvider(eventId));
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context.l10n.guestUpdated);
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(apiErrorMessage(error, context.l10n.updateGuestFailed));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveCompanions() async {
    final service = ref.read(attendeeServiceProvider);
    final conflicts = await service.saveCompanions(
      attendeeId: widget.attendee.id,
      companions: [
        for (final row in _companions)
          Companion(
            id: row.id,
            name: row.name.text.trim(),
            // Sent as typed (0712…, +255…, 255…); the server normalises it.
            phone: row.phone.text.trim().isEmpty ? null : row.phone.text.trim(),
          ),
      ],
    );

    // The same person imported twice gets two invitations — offer to fold
    // their separate guest into this card.
    for (final conflict in conflicts) {
      if (!mounted) return;
      if (!conflict.isGuest) {
        AppToast.info(
          context.l10n.alsoOnCard(conflict.phone, conflict.attendeeName),
        );
        continue;
      }
      if (!conflict.canMerge) {
        AppToast.info(
          context.l10n.alsoGuestNotMerged(
            conflict.phone,
            conflict.attendeeName,
          ),
        );
        continue;
      }
      final merge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.mergeTitle(conflict.attendeeName)),
          content: Text(
            context.l10n.mergeBody(conflict.phone, conflict.attendeeName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.keepBoth),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.merge),
            ),
          ],
        ),
      );
      if (merge == true) {
        await service.mergeGuestIntoCard(
          cardId: widget.attendee.id,
          guestId: conflict.attendeeId,
        );
      }
    }
  }

  Widget _buildCompanions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.companions,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.companionsHint,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        for (final row in _companions)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.name,
                    enabled: !_busy,
                    onChanged: (_) => _companionsChanged = true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.l10n.name,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row.phone,
                    enabled: !_busy,
                    onChanged: (_) => _companionsChanged = true,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.l10n.phone,
                      hintText: context.l10n.optional,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.removeCompanion,
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _companions.remove(row);
                          row.dispose();
                          _companionsChanged = true;
                        }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _companions.add(_CompanionRow.empty());
                  _companionsChanged = true;
                }),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(context.l10n.addCompanion),
        ),
      ],
    );
  }

  Widget _buildCategoryField(
    String eventId,
    List<ContributionCategory> categories,
  ) {
    return GuestCategoryField(
      categories: categories,
      selectedCategoryId: _selectedCategoryId,
      enabled: !_busy,
      label: context.l10n.contributionCategory,
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
              Text(
                context.l10n.editGuest,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_busy,
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
              TanzaniaPhoneField(controller: _phoneController, enabled: !_busy),
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => _buildCategoryField(eventId ?? '', const []),
                data: (categories) =>
                    _buildCategoryField(eventId ?? '', categories),
              ),
              const SizedBox(height: 12),
              PeopleField(
                controller: _peopleController,
                enabled: !_busy,
                label: context.l10n.peopleOnCard,
                minimum: widget.attendee.enteredCount,
                helperText: widget.attendee.enteredCount > 0
                    ? context.l10n.alreadyEntered(widget.attendee.enteredCount)
                    : context.l10n.peopleOnCardHint,
              ),
              const SizedBox(height: 16),
              _buildCompanions(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: context.l10n.amountPaidTzs,
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
                  labelText: context.l10n.pledgeTzs,
                  helperText: context.l10n.pledgeHelper,
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
                    child: Text(context.l10n.saveChanges),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionRow {
  _CompanionRow(this.id, String? name, String? phone)
    : name = TextEditingController(text: name ?? ''),
      phone = TextEditingController(
        text: phone == null ? '' : '0${TanzaniaPhoneField.localPartOf(phone)}',
      );

  factory _CompanionRow.from(Companion companion) =>
      _CompanionRow(companion.id, companion.name, companion.phone);

  factory _CompanionRow.empty() => _CompanionRow(null, null, null);

  final String? id;
  final TextEditingController name;
  final TextEditingController phone;

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}
