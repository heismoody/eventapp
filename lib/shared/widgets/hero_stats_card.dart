import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// The brown stats card at the top of the Contributions and Scan tabs.
/// Matches the dashboard's countdown card — same gradient, same floating
/// translucent circles — so the two "hero" cards read as one family.
class HeroStatsCard extends StatelessWidget {
  const HeroStatsCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -30,
              right: -20,
              child: _HeroBubble(size: 100, opacity: 0.14),
            ),
            const Positioned(
              bottom: -36,
              left: -16,
              child: _HeroBubble(size: 90, opacity: 0.1),
            ),
            Padding(padding: const EdgeInsets.all(18), child: child),
          ],
        ),
      ),
    );
  }
}

class _HeroBubble extends StatelessWidget {
  const _HeroBubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.onPrimary.withValues(alpha: opacity),
      ),
    );
  }
}

class HeroStatItem {
  const HeroStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class HeroStatRow extends StatelessWidget {
  const HeroStatRow({
    super.key,
    required this.items,
    Color? labelColor,
    Color? dividerColor,
  }) : _labelColor = labelColor,
       _dividerColor = dividerColor;

  final List<HeroStatItem> items;
  final Color? _labelColor;
  final Color? _dividerColor;

  Color get labelColor => _labelColor ?? AppColors.muted;
  Color get dividerColor => _dividerColor ?? AppColors.border;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              SizedBox(
                width: 16,
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.6,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: dividerColor,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    items[i].value,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: items[i].color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
}
