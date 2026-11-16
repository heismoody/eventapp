import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../core/config/app_environment.dart';
import '../core/constants/app_colors.dart';
import '../l10n/l10n.dart';
import 'locale_provider.dart';
import 'theme_mode_provider.dart';
import 'router.dart';
import 'theme.dart';

class EventApp extends ConsumerWidget {
  const EventApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppEnvironment.isProd ? 'Cardly' : 'Cardly Dev',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      // AppColors switches in one step, so the theme does too. A cross-fade
      // would leave widgets on the new palette over a half-faded theme.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (device, _) => resolveAppLocale(device),
      builder: (context, child) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final topPadding = MediaQuery.paddingOf(context).top;

        final app = ToastificationWrapper(
          config: ToastificationConfig(
            alignment: Alignment.topCenter,
            itemWidth: screenWidth * 0.95,
            marginBuilder: (context, alignment) {
              return EdgeInsets.only(top: topPadding + 8);
            },
            maxTitleLines: 4,
          ),
          // Inside Localizations, so it sees the language in use.
          child: Builder(
            builder: (context) {
              _usePalette(context);
              final l10n = AppLocalizations.of(context);
              setAppL10n(l10n);
              Intl.defaultLocale = l10n.localeName;
              return child ?? const SizedBox.shrink();
            },
          ),
        );

        if (AppEnvironment.isProd) return app;

        // Corner ribbon on every screen of a dev build, so a test install is
        // never mistaken for the production app.
        return Banner(
          message: 'DEV',
          location: BannerLocation.topEnd,
          color: AppColors.devRibbon,
          child: app,
        );
      },
    );
  }
}

final _lightTheme = buildAppTheme(AppPalette.light);
final _darkTheme = buildAppTheme(AppPalette.dark);

/// Points AppColors at the palette for the theme in use. Screens read
/// AppColors directly rather than through the theme, so when it changes
/// every widget below is rebuilt here, in the same frame, keeping its state.
void _usePalette(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (!AppColors.use(dark ? AppPalette.dark : AppPalette.light)) return;

  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}
