import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_toast.dart';
import '../../../core/constants/app_colors.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';

const smsTemplateVariables = [
  '{name} — Guest name',
  '{event} — Event name',
  '{amount} — Amount paid',
  '{balance} — Outstanding balance',
  '{link} — Digital card link',
];

Future<SmsTemplate?> showSmsTemplateSheet({
  required BuildContext context,
  required String eventId,
  SmsTemplate? template,
}) {
  return showModalBottomSheet<SmsTemplate>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SmsTemplateSheet(
      eventId: eventId,
      template: template,
    ),
  );
}

class _SmsTemplateSheet extends ConsumerStatefulWidget {
  const _SmsTemplateSheet({
    required this.eventId,
    this.template,
  });

  final String eventId;
  final SmsTemplate? template;

  @override
  ConsumerState<_SmsTemplateSheet> createState() => _SmsTemplateSheetState();
}

class _SmsTemplateSheetState extends ConsumerState<_SmsTemplateSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bodyController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _bodyController = TextEditingController(text: widget.template?.body ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final body = _bodyController.text.trim();
    if (name.isEmpty || body.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final service = ref.read(contributionServiceProvider);
      final SmsTemplate saved;
      if (widget.template == null) {
        saved = await service.createSmsTemplate(
          eventId: widget.eventId,
          name: name,
          body: body,
        );
      } else {
        saved = await service.updateSmsTemplate(
          templateId: widget.template!.id,
          name: name,
          body: body,
        );
      }
      ref.invalidate(smsTemplatesProvider(widget.eventId));
      if (mounted) Navigator.pop(context, saved);
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        AppToast.error('Failed to save template');
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
              widget.template == null ? 'Add SMS template' : 'Edit SMS template',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use variables like {name}, {event}, {amount}, {balance}, {link}',
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: !_submitting,
              decoration: const InputDecoration(labelText: 'Template name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: smsTemplateVariables
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _save,
                child: Text(_submitting ? 'Saving...' : 'Save template'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
