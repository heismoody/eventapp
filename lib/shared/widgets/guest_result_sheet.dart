import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/scanner/models/card_status.dart';
import '../../features/scanner/models/scan_result.dart';
import '../../l10n/l10n.dart';

/// Shows a scanned (or manually picked) card. While it has places left the
/// sheet asks how many people are entering and admits them through
/// [onAdmit]; a full card shows who already came in.
Future<void> showGuestResultSheet(
  BuildContext context, {
  required ScanResult result,
  required Future<AdmitResult> Function(CardStatus card, int count) onAdmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _GuestResultSheet(result: result, onAdmit: onAdmit),
  );
}

class _GuestResultSheet extends StatefulWidget {
  const _GuestResultSheet({required this.result, required this.onAdmit});

  final ScanResult result;
  final Future<AdmitResult> Function(CardStatus card, int count) onAdmit;

  @override
  State<_GuestResultSheet> createState() => _GuestResultSheetState();
}

class _GuestResultSheetState extends State<_GuestResultSheet> {
  late int _count = widget.result.card?.placesLeft ?? 1;
  bool _admitting = false;
  AdmitResult? _admitted;

  Future<void> _admit() async {
    setState(() => _admitting = true);
    final outcome = await widget.onAdmit(widget.result.card!, _count);
    if (mounted) {
      setState(() {
        _admitting = false;
        _admitted = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final admitted = _admitted;
    final ready = result.type == ScanResultType.ready && admitted == null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (result.type == ScanResultType.invalid)
              const _InvalidContent()
            else if (admitted != null)
              _AdmittedContent(result: admitted)
            else if (result.type == ScanResultType.full)
              _FullContent(card: result.card!)
            else
              _ReadyContent(
                card: result.card!,
                manual: result.method == 'manual',
                count: _count,
                onCountChanged: _admitting
                    ? null
                    : (value) => setState(() => _count = value),
              ),
            const SizedBox(height: 20),
            if (ready) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _admitting ? null : _admit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: _admitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.how_to_reg_outlined),
                  label: Text(
                    context.l10n.admitPeople(_count),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _admitting ? null : () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    result.method == 'manual'
                        ? context.l10n.done
                        : context.l10n.continueScanning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuestHeading extends StatelessWidget {
  const _GuestHeading({required this.card});

  final CardStatus card;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          card.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(card.phone, style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 14),
        _CategoryBadge(categoryName: card.category),
      ],
    );
  }
}

class _ReadyContent extends StatelessWidget {
  const _ReadyContent({
    required this.card,
    required this.manual,
    required this.count,
    required this.onCountChanged,
  });

  final CardStatus card;
  final bool manual;
  final int count;
  final ValueChanged<int>? onCountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GuestHeading(card: card),
        const SizedBox(height: 12),
        _PlacesPanel(card: card, color: AppColors.primary),
        if (!card.known) ...[
          const SizedBox(height: 12),
          _Note(icon: Icons.info_outline, text: context.l10n.cardUnknownNote),
        ],
        if (manual) ...[
          const SizedBox(height: 12),
          _Note(
            icon: Icons.badge_outlined,
            text: context.l10n.manualCheckInNote,
          ),
        ],
        if (card.placesLeft > 1) ...[
          const SizedBox(height: 16),
          _CountStepper(
            count: count,
            max: card.placesLeft,
            onChanged: onCountChanged,
          ),
        ],
      ],
    );
  }
}

class _FullContent extends StatelessWidget {
  const _FullContent({required this.card});

  final CardStatus card;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.block, color: AppColors.danger, size: 52),
        const SizedBox(height: 8),
        Text(
          context.l10n.cardFullyUsed,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(height: 12),
        _GuestHeading(card: card),
        const SizedBox(height: 12),
        _PlacesPanel(card: card, color: AppColors.danger),
      ],
    );
  }
}

class _AdmittedContent extends StatelessWidget {
  const _AdmittedContent({required this.result});

  final AdmitResult result;

  @override
  Widget build(BuildContext context) {
    final refused = result.outcome == AdmitOutcome.refused;
    final color = refused ? AppColors.danger : AppColors.success;

    return Column(
      children: [
        Icon(
          refused ? Icons.block : Icons.check_circle,
          color: color,
          size: 56,
        ),
        const SizedBox(height: 8),
        Text(
          refused ? context.l10n.notAdmitted : context.l10n.admitted,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        if (refused && result.message != null) ...[
          const SizedBox(height: 4),
          Text(
            result.message!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 12),
        _GuestHeading(card: result.card),
        const SizedBox(height: 12),
        _PlacesPanel(card: result.card, color: color),
        if (result.outcome == AdmitOutcome.queued) ...[
          const SizedBox(height: 12),
          _Note(
            icon: Icons.cloud_upload_outlined,
            text: context.l10n.savedOnPhoneNote,
          ),
        ],
      ],
    );
  }
}

/// "1 of 3 entered" with the entries behind it.
class _PlacesPanel extends StatelessWidget {
  const _PlacesPanel({required this.card, required this.color});

  final CardStatus card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final left = card.placesLeft;
    final summary = card.over > 0
        ? context.l10n.overBy(card.over)
        : left == 0
        ? context.l10n.noPlacesLeft
        : context.l10n.placesLeft(left);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.l10n.enteredOf(card.entered, card.admits),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  context.l10n.enteredWord,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  summary,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (card.entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final entry in card.entries)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.waiting ? Icons.schedule : Icons.login_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _entryLabel(context, entry),
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _entryLabel(BuildContext context, EntryLine entry) {
    final l10n = context.l10n;
    final time = DateFormatter.formatTime(entry.at);
    final people = entry.count == 0
        ? l10n.firstEntry
        : l10n.peopleCount(entry.count);
    final by = entry.byName != null ? ' · ${entry.byName}' : '';
    final waiting = entry.waiting ? ' · ${l10n.waitingToSyncShort}' : '';
    return '$time  ·  $people$by$waiting';
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.count,
    required this.max,
    required this.onChanged,
  });

  final int count;
  final int max;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.peopleEnteringNow,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        IconButton.filledTonal(
          tooltip: context.l10n.oneFewer,
          onPressed: change == null || count <= 1
              ? null
              : () => change(count - 1),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: context.l10n.oneMore,
          onPressed: change == null || count >= max
              ? null
              : () => change(count + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.categoryName});

  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final hasCategory = categoryName != null;
    final color = hasCategory ? AppColors.primary : AppColors.muted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.category.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasCategory ? categoryName! : context.l10n.noCategoryAssigned,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: hasCategory ? 26 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvalidContent extends StatelessWidget {
  const _InvalidContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.error_outline, color: AppColors.danger, size: 56),
        SizedBox(height: 12),
        Text(
          context.l10n.invalidQr,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          context.l10n.invalidQrBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}
