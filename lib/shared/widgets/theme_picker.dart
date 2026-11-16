import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme_mode_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/l10n.dart';

String themeModeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l10n.themeSystem,
  ThemeMode.light => l10n.themeLight,
  ThemeMode.dark => l10n.themeDark,
};

IconData _icon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.brightness_auto_outlined,
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
};

/// Same as phone, Light or Dark, like the portal's account menu.
Future<void> showThemeSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(themeModeProvider);
  final l10n = context.l10n;
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
                l10n.appearance,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final mode in [
              ThemeMode.system,
              ThemeMode.light,
              ThemeMode.dark,
            ])
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(_icon(mode), color: AppColors.onSurface),
                title: Text(
                  themeModeLabel(l10n, mode),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                trailing: mode == current
                    ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : Icon(Icons.circle_outlined, color: AppColors.border),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(themeModeProvider.notifier).choose(mode);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
