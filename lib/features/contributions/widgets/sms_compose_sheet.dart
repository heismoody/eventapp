import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../attendees/services/attendee_service.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';

enum SmsComposeMode { broadcast, individual }

class SmsTemplateOption {
  const SmsTemplateOption({
    this.id,
    required this.name,
    required this.body,
  });

  final String? id;
  final String name;
  final String body;

  String get key => id ?? 'default:$name';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsTemplateOption && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

const defaultSmsTemplates = [
  SmsTemplateOption(
    name: 'Invitation',
    body: 'Hi {name}, your invitation to {event} is ready! View your card: {link}',
  ),
  SmsTemplateOption(
    name: 'Event Reminder',
    body: 'Hi {name}, a friendly reminder — tonight! Please bring your QR card.',
  ),
  SmsTemplateOption(
    name: 'Thank You',
    body: 'Hi {name}, thank you for your contribution of {amount}.',
  ),
];

List<SmsTemplateOption> buildSmsTemplateOptions(List<SmsTemplate> saved) {
  if (saved.isEmpty) return defaultSmsTemplates;
  return saved
      .map(
        (template) => SmsTemplateOption(
          id: template.id,
          name: template.name,
          body: template.body,
        ),
      )
      .toList();
}

SmsTemplateOption? findSmsTemplateOption(
  List<SmsTemplateOption> templates,
  String? key,
) {
  if (templates.isEmpty || key == null) return null;
  for (final template in templates) {
    if (template.key == key) return template;
  }
  return templates.first;
}

Future<void> showSmsComposeSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
  required SmsComposeMode mode,
  VoidCallback? onSent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SmsComposeSheet(
      eventId: eventId,
      mode: mode,
      onSent: onSent,
    ),
  );
}

class _SmsComposeSheet extends ConsumerStatefulWidget {
  const _SmsComposeSheet({
    required this.eventId,
    required this.mode,
    this.onSent,
  });

  final String eventId;
  final SmsComposeMode mode;
  final VoidCallback? onSent;

  @override
  ConsumerState<_SmsComposeSheet> createState() => _SmsComposeSheetState();
}

class _SmsComposeSheetState extends ConsumerState<_SmsComposeSheet> {
  String? _selectedTemplateKey;
  String? _selectedAttendeeId;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(smsTemplatesProvider(widget.eventId));
    final attendeesAsync = ref.watch(attendeesProvider(widget.eventId));
    final creditsAsync = ref.watch(smsCreditsProvider(widget.eventId));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: templatesAsync.when(
        loading: () => const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const Text('Failed to load templates'),
        data: (savedTemplates) {
          final templates = buildSmsTemplateOptions(savedTemplates);
          _selectedTemplateKey ??= templates.first.key;
          if (!templates.any((template) => template.key == _selectedTemplateKey)) {
            _selectedTemplateKey = templates.first.key;
          }
          final selectedTemplate =
              findSmsTemplateOption(templates, _selectedTemplateKey);

          return attendeesAsync.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Text('Failed to load guests'),
            data: (attendees) {
              if (widget.mode == SmsComposeMode.individual &&
                  attendees.isNotEmpty &&
                  _selectedAttendeeId == null) {
                _selectedAttendeeId = attendees.first.id;
              }

              final recipientCount = widget.mode == SmsComposeMode.broadcast
                  ? attendees.length
                  : 1;
              final availableCredits =
                  creditsAsync.maybeWhen(data: (v) => v.available, orElse: () => 0);

              return SingleChildScrollView(
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
                      widget.mode == SmsComposeMode.broadcast
                          ? 'Broadcast SMS'
                          : 'Individual SMS',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.mode == SmsComposeMode.broadcast
                          ? 'Send the same message to all $recipientCount guests'
                          : 'Send a custom message to one guest',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTemplateKey,
                      decoration: InputDecoration(
                        labelText: 'Template',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: templates
                          .map(
                            (template) => DropdownMenuItem(
                              value: template.key,
                              child: Text(template.name),
                            ),
                          )
                          .toList(),
                      onChanged: _sending
                          ? null
                          : (value) => setState(() => _selectedTemplateKey = value),
                    ),
                    const SizedBox(height: 12),
                    if (selectedTemplate != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          selectedTemplate.body,
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    if (widget.mode == SmsComposeMode.individual) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedAttendeeId,
                        decoration: InputDecoration(
                          labelText: 'Guest',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: attendees
                            .map(
                              (attendee) => DropdownMenuItem(
                                value: attendee.id,
                                child: Text('${attendee.name} (+${attendee.phone})'),
                              ),
                            )
                            .toList(),
                        onChanged: _sending
                            ? null
                            : (value) => setState(() => _selectedAttendeeId = value),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Available credits: $availableCredits • Required: $recipientCount',
                      style: TextStyle(
                        color: availableCredits < recipientCount
                            ? AppColors.warning
                            : AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _sending ||
                                recipientCount == 0 ||
                                selectedTemplate == null ||
                                (widget.mode == SmsComposeMode.individual &&
                                    _selectedAttendeeId == null)
                            ? null
                            : () => _send(selectedTemplate.body, attendees.length),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(_sending ? 'Sending...' : 'Send SMS'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _send(String template, int totalGuests) async {
    setState(() => _sending = true);
    try {
      final service = ref.read(contributionServiceProvider);
      final result = await service.sendSmsBroadcast(
        eventId: widget.eventId,
        template: template,
        attendeeIds: widget.mode == SmsComposeMode.individual
            ? [_selectedAttendeeId!]
            : null,
      );

      ref.invalidate(smsBillingProvider(widget.eventId));
      ref.invalidate(smsCreditsProvider(widget.eventId));
      ref.invalidate(smsLogsProvider(widget.eventId));

      if (!mounted) return;

      if (!result.allowed) {
        AppToast.warning(
          result.error ?? 'No SMS credits available for this event',
        );
        return;
      }

      Navigator.pop(context);
      widget.onSent?.call();
      AppToast.success('Sent ${result.sent}, failed ${result.failed}');
    } catch (_) {
      if (mounted) {
        AppToast.error('Failed to send SMS');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
