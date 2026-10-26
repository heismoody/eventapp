import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'skeleton_box.dart';

/// The dashboard's borderless "Summary" row style — a small icon circle,
/// bold value, muted label, optional caption, separated by thin vertical
/// dividers — pulled out so other screens (e.g. the report's Attendance
/// tab) can present stats the same way instead of boxed-in cards.
class SummaryStatItem {
  const SummaryStatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.primary,
    this.caption,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final String? caption;
  final bool isLoading;
}

class SummaryStatRow extends StatelessWidget {
  const SummaryStatRow({super.key, required this.items});

  final List<SummaryStatItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              SizedBox(
                width: 24,
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.6,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1.5,
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            Expanded(child: _SummaryStatItemCentered(data: items[i])),
          ],
        ],
      ),
    );
  }
}

class _SummaryStatItemCentered extends StatelessWidget {
  const _SummaryStatItemCentered({required this.data});

  final SummaryStatItem data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: data.accent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, size: 17, color: data.accent),
        ),
        const SizedBox(height: 10),
        if (data.isLoading)
          const SkeletonBox(width: 28, height: 17, borderRadius: 5)
        else
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppColors.onSurface,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          data.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (data.caption != null) ...[
          const SizedBox(height: 2),
          Text(
            data.caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: data.accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}
