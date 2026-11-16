import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

AppLocalizations? _current;

/// The app's text in its current language, for code that has no
/// BuildContext (toasts raised from services). EventApp keeps it in step.
AppLocalizations get appL10n =>
    _current ?? lookupAppLocalizations(const Locale('en'));

void setAppL10n(AppLocalizations value) => _current = value;

/// [template] with [value] in [valueStyle], wherever the translation put
/// it. Lets a bold name or number sit mid-sentence in either language.
List<InlineSpan> spansWith(
  String Function(String placeholder) template,
  String value,
  TextStyle valueStyle,
) {
  const marker = '\u0000';
  final parts = template(marker).split(marker);
  return [
    for (var i = 0; i < parts.length; i++) ...[
      if (i > 0) TextSpan(text: value, style: valueStyle),
      if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
    ],
  ];
}
