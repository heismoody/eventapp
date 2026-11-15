import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/tanzania_phone_field.dart';
import '../services/event_request_service.dart';
import 'request_sent_screen.dart';

/// "Plan an event with Cardly": for someone who installed the app without
/// an account. It asks Cardly to call them back. It doesn't create an
/// account. Staff do that once the event is agreed.
class RequestEventScreen extends ConsumerStatefulWidget {
  const RequestEventScreen({super.key});

  @override
  ConsumerState<RequestEventScreen> createState() => _RequestEventScreenState();
}

class _RequestEventScreenState extends ConsumerState<RequestEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _venue = TextEditingController();
  final _note = TextEditingController();

  EventType? _eventType;
  GuestRange? _guestRange;
  DateTime? _date;
  bool _dateUnknown = false;
  bool _sending = false;

  /// The server's message per field, shown under that field.
  Map<String, String> _serverErrors = const {};
  bool _showChoiceErrors = false;

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
      helpText: 'Date of the event',
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

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _serverErrors = const {};
      _showChoiceErrors = true;
    });

    final formOk = _formKey.currentState?.validate() ?? false;
    final choicesOk =
        _eventType != null &&
        _guestRange != null &&
        (_date != null || _dateUnknown);
    if (!formOk || !choicesOk) {
      AppToast.warning('Fill in the highlighted parts.');
      return;
    }

    final email = _email.text.trim();
    final note = _note.text.trim();
    final draft = EventRequestDraft(
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

    setState(() => _sending = true);
    try {
      await ref.read(eventRequestServiceProvider).send(draft);
      if (!mounted) return;
      context.go(
        '/plan-event/sent',
        extra: RequestSentDetails(
          name: draft.name,
          phone: draft.phone,
          email: draft.email,
        ),
      );
    } on EventRequestException catch (error) {
      if (!mounted) return;
      setState(() => _serverErrors = error.fields);
      _formKey.currentState?.validate();
      AppToast.error(error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            foregroundColor: AppColors.primary,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/login'),
            ),
            titleSpacing: 0,
            title: const Text(
              'Plan your event',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (AppEnvironment.allowsServerOverride) ...[
                      _DevServerLine(onChanged: () => setState(() {})),
                      const SizedBox(height: 16),
                    ],
                    const _SectionLabel('About you'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstName,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: const InputDecoration(
                              labelText: 'First name',
                            ),
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Enter your first name'
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
                            decoration: const InputDecoration(
                              labelText: 'Last name',
                            ),
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Enter your last name'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TanzaniaPhoneField(controller: _phone),
                    if (_fieldError('phone') case final message?)
                      _ErrorText(message)
                    else
                      const _HintText("We'll call or WhatsApp this number."),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        helperText: "We'll email you a copy of your request.",
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isNotEmpty &&
                            !RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value)) {
                          return "This email doesn't look right";
                        }
                        return _fieldError('email');
                      },
                    ),
                    const SizedBox(height: 28),
                    Text('Type of event', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in EventType.values)
                          _Choice(
                            label: type.label,
                            selected: _eventType == type,
                            onTap: () => setState(() => _eventType = type),
                          ),
                      ],
                    ),
                    if (_showChoiceErrors && _eventType == null)
                      const _ErrorText('Choose the type of event'),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DateField(
                            date: _date,
                            unknown: _dateUnknown,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _venue,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Venue',
                              hintText: 'Hall, hotel or town',
                            ),
                            validator: (v) => (v ?? '').trim().length < 2
                                ? 'Enter the venue'
                                : _fieldError('venue'),
                          ),
                        ),
                      ],
                    ),
                    if (_showChoiceErrors && _date == null && !_dateUnknown)
                      const _ErrorText('Choose a date, or tick “Not sure”')
                    else if (_fieldError('eventDate') case final message?)
                      _ErrorText(message),
                    CheckboxListTile(
                      value: _dateUnknown,
                      onChanged: (v) => setState(() {
                        _dateUnknown = v ?? false;
                        if (_dateUnknown) _date = null;
                      }),
                      title: const Text('Not sure of the date yet'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 20),
                    Text('How many guests?', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final (i, range) in GuestRange.values.indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _Choice(
                              label: range.label,
                              selected: _guestRange == range,
                              onTap: () => setState(() => _guestRange = range),
                              square: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_showChoiceErrors && _guestRange == null)
                      const _ErrorText('Choose roughly how many guests'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _note,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Anything else? (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send request'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Free, no commitment. We only use your details to contact '
                      'you about this event.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
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
                  color: selected ? Colors.white : AppColors.onSurface,
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
    final label = unknown
        ? 'Not sure yet'
        : date == null
        ? null
        : DateFormat('d MMM yyyy').format(date!);

    return InkWell(
      onTap: unknown ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        isEmpty: label == null,
        isFocused: false,
        decoration: const InputDecoration(
          labelText: 'Date',
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
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
        const Icon(Icons.dns_outlined, size: 16, color: AppColors.muted),
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
