import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

const supportedAppLocales = [Locale('en'), Locale('sw')];

/// Until someone picks a language, the app follows the phone: Kiswahili
/// on a Swahili phone, English on anything else.
Locale resolveAppLocale(Locale? device) =>
    device?.languageCode == 'sw' ? const Locale('sw') : const Locale('en');

/// The language the person chose, or null to follow the phone.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'app_language';

  @override
  Locale? build() {
    final code = ref.read(sharedPreferencesProvider).getString(_key);
    return supportedAppLocales.where((l) => l.languageCode == code).firstOrNull;
  }

  Future<void> choose(Locale locale) async {
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
