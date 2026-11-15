import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eventapp/app/app.dart';
import 'package:eventapp/app/providers.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const EventApp(),
      ),
    );

    // First launch: the welcome screen and its two ways in.
    expect(find.text('Plan an event with Cardly'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
