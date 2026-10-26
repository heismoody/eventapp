import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// One category's share of the whole — label plus the amount it represents.
/// The chart computes percentages itself from the slice values.
class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// A fixed, hand-rolled palette cycled across categories in the order
/// they're given — distinct enough to tell apart at a glance without
/// needing a design-time color picker per category.
const List<Color> categoryPalette = [
  AppColors.primary,
  AppColors.accent,
  AppColors.success,
  AppColors.warning,
  Color(0xFF6366F1),
  Color(0xFFEC4899),
  AppColors.danger,
  Color(0xFF0EA5E9),
];

/// A donut chart for compositional data (each category's share of a total)
/// — a ring rather than a filled pie so a total can sit in the center,
/// with a colored legend listing each slice's amount and share.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.slices,
    this.size = 168,
    this.strokeWidth = 26,
    this.centerLabel,
    this.centerValue,
  });

  final List<CategorySlice> slices;
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final String? centerValue;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (a, b) => a + b.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DonutPainter(
                  slices: slices,
                  strokeWidth: strokeWidth,
                ),
              ),
              if (centerValue != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerValue!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (centerLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        centerLabel!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final slice in slices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slice.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slice.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        total > 0
                            ? '${(slice.value / total * 100).round()}%'
                            : '0%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.strokeWidth});

  final List<CategorySlice> slices;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (a, b) => a + b.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total <= 0) {
      final track = Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 2 * math.pi, false, track);
      return;
    }

    var startAngle = -math.pi / 2;
    // A hairline gap between slices, skipped when there's only one.
    final gap = slices.length > 1 ? 0.03 : 0.0;

    for (final slice in slices) {
      final sweep = (slice.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        (sweep - gap).clamp(0, sweep),
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.strokeWidth != strokeWidth;
}
