import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/l10n.dart';
import '../services/event_request_service.dart';

class RequestSentDetails {
  const RequestSentDetails({
    required this.name,
    required this.phone,
    required this.email,
  });

  final String name;
  final String phone;
  final String? email;
}

/// After "Send request": what happens next, and a way to reach Cardly now.
class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key, required this.details});

  final RequestSentDetails? details;

  Future<void> _open(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      AppToast.error(
        appL10n.couldntOpenCallUs(
          CardlyContact.display(CardlyContact.callNumbers.first),
        ),
      );
    }
  }

  Future<void> _call(BuildContext context) async {
    final number = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final n in CardlyContact.callNumbers)
              ListTile(
                leading: const Icon(Icons.call_outlined),
                title: Text(CardlyContact.display(n)),
                onTap: () => Navigator.pop(context, n),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (number != null) await _open(Uri(scheme: 'tel', path: '+$number'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final d = details;
    final firstName = d?.name.trim().split(RegExp(r'\s+')).first;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/login');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.onPrimary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                firstName == null
                    ? l10n.requestWithUs
                    : l10n.thanksRequestWithUs(firstName),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                  children: [
                    if (d == null)
                      TextSpan(text: l10n.callYouSoon)
                    else
                      ...spansWith(
                        l10n.callYouOn,
                        CardlyContact.display(d.phone),
                        TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (d?.email != null)
                      TextSpan(text: ' ${l10n.emailedCopyTo(d!.email!)}'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.whatHappensNext,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Step(1, l10n.nextStep1),
                      _Step(2, l10n.nextStep2),
                      _Step(3, l10n.nextStep3, last: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.cantWait,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(
                        Uri.parse('https://wa.me/${CardlyContact.whatsapp}'),
                      ),
                      icon: const Icon(Icons.chat_outlined),
                      label: Text(l10n.whatsApp),
                      style: _contactStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _call(context),
                      icon: const Icon(Icons.call_outlined),
                      label: Text(l10n.callUs),
                      style: _contactStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  l10n.done,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _contactStyle = OutlinedButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  foregroundColor: AppColors.primary,
  backgroundColor: AppColors.surface,
  side: BorderSide(color: AppColors.border),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

class _Step extends StatelessWidget {
  const _Step(this.number, this.text, {this.last = false});

  final int number;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondaryAlt,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    ),
  );
}
