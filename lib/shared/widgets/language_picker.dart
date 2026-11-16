import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/l10n.dart';

/// Each language named in itself, so it can be found whatever is showing.
const _languages = [
  (locale: Locale('en'), short: 'EN', name: 'English'),
  (locale: Locale('sw'), short: 'SW', name: 'Kiswahili'),
];

/// "EN | SW" for the top corner of the welcome photo: white on the dark
/// overlay, the language in use filled.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = Localizations.localeOf(context).languageCode;
    return Semantics(
      label: context.l10n.language,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.scrim.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.onPrimary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final language in _languages)
              _SwitchSegment(
                label: language.short,
                semanticsLabel: language.name,
                selected: language.locale.languageCode == current,
                onTap: () =>
                    ref.read(localeProvider.notifier).choose(language.locale),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchSegment extends StatelessWidget {
  const _SwitchSegment({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 44pt tall target around a slim pill.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.onPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: selected ? AppColors.primary : AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Settings version: a sheet with both languages.
Future<void> showLanguageSheet(BuildContext context, WidgetRef ref) {
  final current = Localizations.localeOf(context).languageCode;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                context.l10n.languageSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final language in _languages)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(
                  language.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: language.locale.languageCode == current
                    ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : Icon(Icons.circle_outlined, color: AppColors.border),
                selected: language.locale.languageCode == current,
                onTap: () {
                  ref.read(localeProvider.notifier).choose(language.locale);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
