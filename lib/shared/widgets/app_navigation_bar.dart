import 'package:flutter/material.dart';

/// One tab in [AppNavigationBar].
class AppNavigationItem {
  const AppNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The app's bottom bar. Looks like Material 3's NavigationBar and reads
/// its NavigationBarTheme, but every label stays on one line: a label too
/// long for its tab (a narrow phone, a long word, a large text setting)
/// shrinks just enough to fit instead of breaking across two lines, so the
/// tabs stay level.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barTheme = NavigationBarTheme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: barTheme.backgroundColor ?? colors.surfaceContainer,
      elevation: barTheme.elevation ?? 3,
      shadowColor: barTheme.shadowColor ?? Colors.transparent,
      surfaceTintColor: barTheme.surfaceTintColor ?? Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barTheme.height ?? 80,
          child: Row(
            children: [
              for (final (index, item) in items.indexed)
                Expanded(
                  child: _Destination(
                    item: item,
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _indicatorSize = Size(64, 32);
  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barTheme = NavigationBarTheme.of(context);
    final colors = theme.colorScheme;
    final states = {if (selected) WidgetState.selected};

    final labelStyle =
        (barTheme.labelTextStyle?.resolve(states) ??
                theme.textTheme.labelMedium ??
                const TextStyle(fontSize: 12))
            .copyWith(
              color:
                  barTheme.labelTextStyle?.resolve(states)?.color ??
                  (selected ? colors.onSurface : colors.onSurfaceVariant),
            );
    final iconColor = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Tooltip(
      message: item.label,
      excludeFromSemantics: true,
      // One node per tab for screen readers: its name, selected state and
      // tap action (the inner widgets' own semantics are left out).
      child: Semantics(
        container: true,
        button: true,
        selected: selected,
        label: item.label,
        onTap: onTap,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.fromSize(
                  size: _indicatorSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1 : 0.4,
                        duration: _duration,
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: selected ? 1 : 0,
                          duration: _duration,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color:
                                  barTheme.indicatorColor ??
                                  colors.secondaryContainer,
                              shape:
                                  barTheme.indicatorShape ??
                                  const StadiumBorder(),
                            ),
                            child: SizedBox.fromSize(size: _indicatorSize),
                          ),
                        ),
                      ),
                      // Tap feedback on the pill only, as in Material 3.
                      Positioned.fill(
                        child: Material(
                          type: MaterialType.transparency,
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onTap,
                            customBorder: const StadiumBorder(),
                            child: Center(
                              child: Icon(
                                selected ? item.selectedIcon : item.icon,
                                size: 24,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
