import 'package:eventapp/shared/widgets/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// The longest set of tabs the app shows (an owner who can also scan), in
// both languages.
const _labels = {
  'en': ['Dashboard', 'Scan', 'Guests', 'Contributions', 'Team', 'Settings'],
  'sw': ['Muhtasari', 'Skani', 'Wageni', 'Michango', 'Timu', 'Mipangilio'],
};

void main() {
  // Narrow and common phone widths, at normal and enlarged text sizes.
  for (final width in [320.0, 360.0, 393.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final MapEntry(key: lang, value: labels) in _labels.entries) {
        testWidgets('labels stay on one line: ${width.toInt()}dp, '
            'text x$scale, $lang', (tester) async {
          tester.view.physicalSize = Size(width * 3, 800 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                bottomNavigationBar: AppNavigationBar(
                  selectedIndex: 3,
                  onSelected: (_) {},
                  items: [
                    for (final label in labels)
                      AppNavigationItem(
                        icon: Icons.circle_outlined,
                        selectedIcon: Icons.circle,
                        label: label,
                      ),
                  ],
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          final tabWidth = width / labels.length;
          for (final label in labels) {
            final text = find.text(label);
            final paragraph = tester.renderObject<RenderParagraph>(text);
            // One line: never split mid-word.
            expect(paragraph.didExceedMaxLines, isFalse, reason: label);
            // Drawn inside its own tab.
            final drawn = tester.getRect(text);
            expect(drawn.width, lessThanOrEqualTo(tabWidth), reason: label);
          }
          // All tabs level: every label sits on the same baseline.
          final tops = {
            for (final label in labels)
              tester.getCenter(find.text(label)).dy.round(),
          };
          expect(tops.length, 1);
        });
      }
    }
  }

  testWidgets('tapping a tab reports it, and it reads as selected', (
    tester,
  ) async {
    var tapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppNavigationBar(
            selectedIndex: 0,
            onSelected: (index) => tapped = index,
            items: const [
              AppNavigationItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Dashboard',
              ),
              AppNavigationItem(
                icon: Icons.people_outline,
                selectedIcon: Icons.people,
                label: 'Guests',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Guests'));
    expect(tapped, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Dashboard')),
      matchesSemantics(
        label: 'Dashboard',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
  });
}
