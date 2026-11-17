import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/tanzania_phone_field.dart';
import '../services/event_request_service.dart';

/// "Plan an event with Cardly": for someone who installed the app without
/// an account. It asks Cardly to call them back. It doesn't create an
/// account. Staff do that once the event is agreed.
class RequestEventScreen extends ConsumerStatefulWidget {
  const RequestEventScreen({super.key});

  @override
  ConsumerState<RequestEventScreen> createState() => _RequestEventScreenState();
}

enum _Step { event, you, review }

class _RequestEventScreenState extends ConsumerState<RequestEventScreen> {
  final _eventForm = GlobalKey<FormState>();
  final _youForm = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _venue = TextEditingController();
  final _note = TextEditingController();

  _Step _step = _Step.event;

  /// Which way the last move went, so the next step slides in from the
  /// right side.
  bool _forward = true;

  EventType? _eventType;
  GuestRange? _guestRange;
  DateTime? _date;
  bool _dateUnknown = false;
  bool _sending = false;

  /// The server's message per field, shown under that field.
  Map<String, String> _serverErrors = const {};
  bool _showChoiceErrors = false;

  static const _youFields = {'name', 'phone', 'email'};

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _venue.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today.add(const Duration(days: 30)),
      firstDate: today,
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: context.l10n.dateOfEvent,
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateUnknown = false;
        _serverErrors = {..._serverErrors}..remove('eventDate');
      });
    }
  }

  String? _fieldError(String key) => _serverErrors[key];

  void _goTo(_Step step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = step.index > _step.index;
      _step = step;
    });
  }

  bool get _eventChoicesOk =>
      _eventType != null &&
      _guestRange != null &&
      (_date != null || _dateUnknown);

  /// Checks the step on screen before moving on from it.
  void _continue() {
    switch (_step) {
      case _Step.event:
        setState(() => _showChoiceErrors = true);
        final formOk = _eventForm.currentState?.validate() ?? false;
        if (!formOk || !_eventChoicesOk) return;
        _goTo(_Step.you);
      case _Step.you:
        if (!(_youForm.currentState?.validate() ?? false)) return;
        _goTo(_Step.review);
      case _Step.review:
        _send();
    }
  }

  void _back() {
    if (_sending) return;
    if (_step == _Step.event) {
      context.canPop() ? context.pop() : context.go('/login');
    } else {
      _goTo(_Step.values[_step.index - 1]);
    }
  }

  EventRequestDraft get _draft {
    final email = _email.text.trim();
    final note = _note.text.trim();
    return EventRequestDraft(
      // The server keeps one name field; old app builds send it whole.
      name: '${_firstName.text.trim()} ${_lastName.text.trim()}',
      phone: TanzaniaPhoneField.normalize(_phone.text),
      email: email.isEmpty ? null : email,
      eventType: _eventType!,
      eventDate: _dateUnknown ? null : _date,
      venue: _venue.text.trim(),
      guestRange: _guestRange!,
      note: note.isEmpty ? null : note,
    );
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final draft = _draft;
    setState(() {
      _serverErrors = const {};
      _sending = true;
    });
    try {
      await ref.read(eventRequestServiceProvider).send(draft);
      if (!mounted) return;
      context.go('/plan-event/sent');
    } on EventRequestException catch (error) {
      if (!mounted) return;
      setState(() => _serverErrors = error.fields);
      // Take them to the step with the field the server didn't accept.
      if (error.fields.isNotEmpty) {
        final onYou = error.fields.keys.every(_youFields.contains);
        _goTo(onYou ? _Step.you : _Step.event);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          (onYou ? _youForm : _eventForm).currentState?.validate();
        });
      }
      AppToast.error(error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = _step == _Step.review;

    return PopScope(
      canPop: _step == _Step.event && !_sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          leading: IconButton(
            tooltip: l10n.back,
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
          titleSpacing: 0,
          title: Text(
            l10n.planYourEvent,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(34),
            child: _StepProgress(
              current: _step.index,
              total: _Step.values.length,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                // Steps start at the top. The default would centre a short
                // step in the middle of the screen.
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(_step);
                  final from = (incoming == _forward) ? 0.12 : -0.12;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(from, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: switch (_step) {
                      _Step.event => _buildEvent(context),
                      _Step.you => _buildYou(context),
                      _Step.review => _buildReview(context),
                    },
                  ),
                ),
              ),
            ),
            // In the body rather than the bottom bar, so it rides up with
            // the keyboard.
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: _sending ? null : _continue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _sending
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(last ? l10n.sendRequest : l10n.continueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.onSurface,
      ),
    ),
  );

  Widget _buildEvent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Form(
      key: _eventForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (AppEnvironment.allowsServerOverride) ...[
            _DevServerLine(onChanged: () => setState(() {})),
            const SizedBox(height: 12),
          ],
          _heading(l10n.stepEventHeading),
          Text(l10n.typeOfEvent, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in EventType.values)
                _Choice(
                  label: type.label(l10n),
                  selected: _eventType == type,
                  onTap: () => setState(() => _eventType = type),
                ),
            ],
          ),
          if (_showChoiceErrors && _eventType == null)
            _ErrorText(l10n.chooseEventType),
          const SizedBox(height: 24),
          _DateField(date: _date, unknown: _dateUnknown, onTap: _pickDate),
          if (_showChoiceErrors && _date == null && !_dateUnknown)
            _ErrorText(l10n.chooseDateOrNotSure)
          else if (_fieldError('eventDate') case final message?)
            _ErrorText(message),
          CheckboxListTile(
            value: _dateUnknown,
            onChanged: (v) => setState(() {
              _dateUnknown = v ?? false;
              if (_dateUnknown) _date = null;
            }),
            title: Text(l10n.notSureOfDate),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _venue,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.venue,
              hintText: l10n.venueHint,
            ),
            validator: (v) => (v ?? '').trim().length < 2
                ? l10n.enterVenue
                : _fieldError('venue'),
          ),
          const SizedBox(height: 24),
          Text(l10n.howManyGuests, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, range) in GuestRange.values.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _Choice(
                    label: range.label(l10n),
                    selected: _guestRange == range,
                    onTap: () => setState(() => _guestRange = range),
                    square: true,
                  ),
                ),
              ],
            ],
          ),
          if (_showChoiceErrors && _guestRange == null)
            _ErrorText(l10n.chooseGuestRange),
        ],
      ),
    );
  }

  Widget _buildYou(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _youForm,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heading(l10n.stepYouHeading),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstName,
                    autofocus: _firstName.text.isEmpty,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.givenName],
                    decoration: InputDecoration(labelText: l10n.firstName),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? l10n.enterFirstName
                        : _fieldError('name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.familyName],
                    decoration: InputDecoration(labelText: l10n.lastName),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l10n.enterLastName : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TanzaniaPhoneField(controller: _phone),
            if (_fieldError('phone') case final message?)
              _ErrorText(message)
            else
              _HintText(l10n.phoneContactHint),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _continue(),
              decoration: InputDecoration(
                labelText: l10n.emailOptional,
                helperText: l10n.emailCopyHelper,
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isNotEmpty &&
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                  return l10n.emailInvalid;
                }
                return _fieldError('email');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final d = _draft;
    final date = d.eventDate == null
        ? l10n.notSureYet
        : DateFormat('d MMMM yyyy', l10n.localeName).format(d.eventDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(l10n.stepReviewHeading),
        _ReviewCard(
          title: l10n.yourEvent,
          onEdit: () => _goTo(_Step.event),
          rows: [
            (l10n.eventLabel, d.eventType.label(l10n)),
            (l10n.date, date),
            (l10n.venue, d.venue),
            (l10n.guests, d.guestRange.label(l10n)),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: l10n.aboutYou,
          onEdit: () => _goTo(_Step.you),
          rows: [
            (l10n.name, d.name),
            (l10n.phone, CardlyContact.display(d.phone)),
            (l10n.email, d.email ?? l10n.noEmail),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _note,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.anythingElse,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.requestDisclaimer,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

/// "Step 1 of 3" over three segments, filled up to the current step.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.stepOfTotal(current + 1, total),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.stepOfTotal(current + 1, total),
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < total; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= current
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One group of answers on the last step, with a way back to change them.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final List<(String, String)> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  context.l10n.edit,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      label,
                      style: TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 12),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );
}

/// One option in a pick-one group: a pill, or a rounded square when the
/// options share a row.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.square = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(square ? 12 : 999);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: EdgeInsets.symmetric(horizontal: square ? 4 : 16),
            // widthFactor 1: as wide as the label, so pills wrap in rows.
            // In the guests row Expanded still makes each one fill its share.
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.onPrimary : AppColors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Looks like the other fields, opens the date picker.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.unknown,
    required this.onTap,
  });

  final DateTime? date;
  final bool unknown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = unknown
        ? l10n.notSureYet
        : date == null
        ? null
        : DateFormat('d MMM yyyy', l10n.localeName).format(date!);

    return InkWell(
      onTap: unknown ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        isEmpty: label == null,
        isFocused: false,
        decoration: InputDecoration(
          labelText: l10n.date,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          label ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// Dev builds only: which server requests go to, and a way to change it
/// without signing out first.
class _DevServerLine extends ConsumerWidget {
  const _DevServerLine({required this.onChanged});

  final VoidCallback onChanged;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final controller = TextEditingController(
      text: AppEnvironment.baseUrl(prefs),
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          autofocus: true,
          decoration: const InputDecoration(
            helperText: 'http://localhost:3000 over USB, or appdev',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await prefs.setString(ApiConfig.baseUrlKey, value);
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.read(eventRequestServiceProvider).serverUrl;
    return Row(
      children: [
        Icon(Icons.dns_outlined, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Dev build, sending to $url',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
        TextButton(
          onPressed: () => _edit(context, ref),
          child: const Text('Change'),
        ),
      ],
    );
  }
}
