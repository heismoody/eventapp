import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../attendees/services/attendee_service.dart';
import '../../attendees/widgets/attendee_display.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';

/// Lets an owner set a pledge and/or record a payment for one or more
/// guests at once, without going through each guest's own detail page.
Future<bool?> showAddContributionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _AddContributionSheet(eventId: eventId),
  );
}

class _AddContributionSheet extends ConsumerStatefulWidget {
  const _AddContributionSheet({required this.eventId});

  final String eventId;

  @override
  ConsumerState<_AddContributionSheet> createState() =>
      _AddContributionSheetState();
}

class _AddContributionSheetState extends ConsumerState<_AddContributionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pledgeController = TextEditingController();
  final _amountController = TextEditingController();
  final _searchController = TextEditingController();
  final Map<String, AttendeeRecord> _selected = {};
  bool _submitting = false;

  @override
  void dispose() {
    _pledgeController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _validateOptionalAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
    return null;
  }

  void _toggle(AttendeeRecord attendee) {
    setState(() {
      if (_selected.containsKey(attendee.id)) {
        _selected.remove(attendee.id);
      } else {
        _selected[attendee.id] = attendee;
      }
    });
  }

  List<AttendeeRecord> _filterFor(
    List<AttendeeRecord> attendees,
    String? categoryId,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return attendees.where((a) {
      if (query.isNotEmpty && !a.name.toLowerCase().contains(query)) {
        return false;
      }
      if (categoryId != null && a.categoryId != categoryId) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildGuestsPane(List<AttendeeRecord> attendees, String? categoryId) {
    final filtered = _filterFor(attendees, categoryId);

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No guests found',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    final allSelected = filtered.every((a) => _selected.containsKey(a.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: Row(
            children: [
              Text(
                '${filtered.length} guest${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _submitting ? null : () => _selectAll(filtered),
                child: Text(allSelected ? 'Clear all' : 'Select all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final attendee = filtered[index];
              final selected = _selected.containsKey(attendee.id);
              return _GuestSelectCard(
                initials: guestInitials(attendee.name),
                name: attendee.name,
                subtitle: attendee.categoryName ?? attendee.phone,
                selected: selected,
                onTap: _submitting ? null : () => _toggle(attendee),
              );
            },
          ),
        ),
      ],
    );
  }

  void _selectAll(List<AttendeeRecord> visible) {
    setState(() {
      final allSelected = visible.every((a) => _selected.containsKey(a.id));
      if (allSelected) {
        for (final a in visible) {
          _selected.remove(a.id);
        }
      } else {
        for (final a in visible) {
          _selected[a.id] = a;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      AppToast.warning('Pick at least one guest');
      return;
    }

    final pledgeText = _pledgeController.text.trim();
    final amountText = _amountController.text.trim();
    if (pledgeText.isEmpty && amountText.isEmpty) {
      AppToast.warning('Enter a pledge, an amount paid, or both');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final pledge = pledgeText.isEmpty ? null : double.parse(pledgeText);
    final amount = amountText.isEmpty ? null : double.parse(amountText);
    final service = ref.read(contributionServiceProvider);

    setState(() => _submitting = true);
    var succeeded = 0;
    for (final attendee in _selected.values) {
      try {
        if (pledge != null) {
          await service.setPledge(
            attendeeId: attendee.id,
            pledgeAmount: pledge,
          );
        }
        if (amount != null) {
          await service.recordPayment(
            attendeeId: attendee.id,
            paymentReceived: amount,
          );
        }
        succeeded++;
      } catch (_) {
        // Keep going — report the partial result once the batch is done.
      }
    }

    ref.invalidate(attendeesProvider(widget.eventId));
    if (!mounted) return;

    final failed = _selected.length - succeeded;
    setState(() => _submitting = false);

    if (succeeded > 0) {
      Navigator.pop(context, true);
      AppToast.success(
        failed == 0
            ? 'Updated $succeeded guest${succeeded == 1 ? '' : 's'}'
            : 'Updated $succeeded, failed for $failed',
      );
    } else {
      AppToast.error('Failed to update contribution');
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendeesAsync = ref.watch(attendeesProvider(widget.eventId));
    final categoriesAsync = ref.watch(
      contributionCategoriesProvider(widget.eventId),
    );
    final categories = categoriesAsync.maybeWhen(
      data: (v) => v,
      orElse: () => const <ContributionCategory>[],
    );
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Text(
              _selected.isEmpty
                  ? 'Add contribution'
                  : 'Add contribution (${_selected.length} selected)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  hintText: 'Search guest by name',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? attendeesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(
                      child: Text(
                        'Could not load guests',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                    data: (attendees) => _buildGuestsPane(attendees, null),
                  )
                : DefaultTabController(
                    length: categories.length + 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                          child: TabBar(
                            isScrollable: categories.length + 1 > 4,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.muted,
                            indicatorColor: AppColors.primary,
                            dividerColor: Colors.transparent,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.4,
                            ),
                            tabs: [
                              const Tab(text: 'ALL'),
                              for (final category in categories)
                                Tab(text: category.name.toUpperCase()),
                            ],
                          ),
                        ),
                        Expanded(
                          child: attendeesAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, _) => const Center(
                              child: Text(
                                'Could not load guests',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                            data: (attendees) => TabBarView(
                              children: [
                                _buildGuestsPane(attendees, null),
                                for (final category in categories)
                                  _buildGuestsPane(attendees, category.id),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pledgeController,
                          enabled: !_submitting,
                          decoration: const InputDecoration(
                            labelText: 'Pledge per guest (TZS)',
                            helperText: 'What they committed to give',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                          ],
                          validator: _validateOptionalAmount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          enabled: !_submitting,
                          decoration: const InputDecoration(
                            labelText: 'Paid per guest (TZS)',
                            helperText: 'Money received now',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                          ],
                          validator: _validateOptionalAmount,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(
                        _submitting
                            ? 'Saving...'
                            : _selected.length > 1
                            ? 'Save for ${_selected.length} guests'
                            : 'Save',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestSelectCard extends StatelessWidget {
  const _GuestSelectCard({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String initials;
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
