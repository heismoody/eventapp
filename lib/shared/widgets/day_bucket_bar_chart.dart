import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A day-bucketed, tap-for-tooltip bar chart — pulled out of the dashboard's
/// Trends card so the same visual language (pill bars, pale full-height
/// tracks, dashed gridlines, "today" highlight) can be reused anywhere a
/// list of dated events (optionally with amounts) needs charting, without
/// duplicating the chart itself per screen.
class DayBucketBarChart extends StatefulWidget {
  const DayBucketBarChart({
    super.key,
    required this.dates,
    this.amounts,
    required this.accent,
    required this.highlight,
    this.chartHeight = 230,
    this.maxPoints = 7,
  });

  /// One entry per event; bucketed by calendar day.
  final List<DateTime> dates;

  /// When set (index-aligned with [dates]), each bucket sums the matching
  /// amount instead of counting occurrences, and the tooltip shows
  /// "TZS `<amount>`" instead of a plain count.
  final List<double>? amounts;

  final Color accent;

  /// Color for today's bar/label, so "now" stands out from the rest.
  final Color highlight;

  final double chartHeight;
  final int maxPoints;

  @override
  State<DayBucketBarChart> createState() => _DayBucketBarChartState();
}

class _DayBucketBarChartState extends State<DayBucketBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final buckets = bucketByActualDates(
      widget.dates,
      widget.amounts,
      maxPoints: widget.maxPoints,
    );
    final maxValue = buckets
        .map((b) => b.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final niceMax = niceAxisMax(maxValue);
    final chartHeight = widget.chartHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: chartHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final frac in [0.0, 0.25, 0.5, 0.75, 1.0])
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: (chartHeight - 1) * frac,
                  child: const _DashedLine(),
                ),
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < buckets.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            _selectedIndex = _selectedIndex == i ? null : i;
                          }),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              if (_selectedIndex == i)
                                Positioned(
                                  bottom:
                                      displayBarHeight(
                                        buckets[i].value,
                                        niceMax,
                                        chartHeight,
                                      ) +
                                      8,
                                  child: ChartTooltip(
                                    text: widget.amounts != null
                                        ? 'TZS ${compactAmount(buckets[i].value)}'
                                        : '${buckets[i].value.round()}',
                                    color: isSameDayAsToday(buckets[i].date)
                                        ? widget.highlight
                                        : widget.accent,
                                  ),
                                ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 14,
                                  height: chartHeight,
                                  decoration: BoxDecoration(
                                    color: AppColors.border.withValues(
                                      alpha: 0.35,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: _Bar(
                                  value: buckets[i].value,
                                  maxValue: niceMax,
                                  chartHeight: chartHeight,
                                  color: isSameDayAsToday(buckets[i].date)
                                      ? widget.highlight
                                      : widget.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < buckets.length; i++)
              Expanded(
                child: Text(
                  buckets[i].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSameDayAsToday(buckets[i].date)
                        ? widget.highlight
                        : AppColors.muted,
                    fontSize: 11,
                    fontWeight: isSameDayAsToday(buckets[i].date)
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A single thin, fully-rounded (pill) bar — matches the reference chart's
/// capsule bars rather than wide rectangular ones.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.maxValue,
    required this.chartHeight,
    required this.color,
  });

  final double value;
  final double maxValue;
  final double chartHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: 14,
      height: displayBarHeight(value, maxValue, chartHeight),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// Scales [value] against [maxValue] the way a normal bar chart would, but
// caps the tallest possible bar at [maxBarFillFraction] of the graph's
// height instead of 100% — so even the largest value still leaves visible
// headroom above it, and the track never looks "full".
const maxBarFillFraction = 0.85;

double displayBarHeight(double value, double maxValue, double chartHeight) {
  if (value <= 0) return 0;
  final cap = chartHeight * maxBarFillFraction;
  if (maxValue <= 0) return 8.0;
  return (cap * (value / maxValue)).clamp(8.0, cap);
}

/// A small floating label shown above a tapped bar with its exact value.
class ChartTooltip extends StatelessWidget {
  const ChartTooltip({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A horizontal dashed gridline, drawn to the width it's given.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedLinePainter(), size: Size.infinite),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

String compactAmount(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}

/// Rounds [value] up to a "nice" axis maximum (1/2/5 × a power of ten), the
/// same way most charting libraries pick gridline scales.
double niceAxisMax(double value) {
  if (value <= 0) return 4;
  final magnitude = math
      .pow(10, (math.log(value) / math.ln10).floor())
      .toDouble();
  final residual = value / magnitude;
  double niceResidual;
  if (residual <= 1) {
    niceResidual = 1;
  } else if (residual <= 2) {
    niceResidual = 2;
  } else if (residual <= 5) {
    niceResidual = 5;
  } else {
    niceResidual = 10;
  }
  return niceResidual * magnitude;
}

class TrendBucket {
  const TrendBucket({
    required this.date,
    required this.label,
    required this.value,
  });

  final DateTime date;
  final String label;
  final double value;
}

const _monthShortNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Groups [dates] by the actual calendar day they fall on — days with no
/// record are simply absent, not shown as empty bars. Only the most recent
/// [maxPoints] distinct days are kept, so the chart stays readable on a
/// phone without scrolling. When [amounts] is given (index-aligned with
/// [dates]), each bucket sums the matching amounts instead of counting
/// occurrences.
List<TrendBucket> bucketByActualDates(
  List<DateTime> dates,
  List<double>? amounts, {
  int maxPoints = 7,
}) {
  final byDay = <DateTime, double>{};

  for (var i = 0; i < dates.length; i++) {
    final local = dates[i].toLocal();
    final day = DateTime(local.year, local.month, local.day);
    byDay[day] = (byDay[day] ?? 0) + (amounts != null ? amounts[i] : 1);
  }

  final sortedDays = byDay.keys.toList()..sort();
  final recentDays = sortedDays.length > maxPoints
      ? sortedDays.sublist(sortedDays.length - maxPoints)
      : sortedDays;

  return [
    for (final day in recentDays)
      TrendBucket(
        date: day,
        label: '${day.day} ${_monthShortNames[day.month - 1]}',
        value: byDay[day]!,
      ),
  ];
}

bool isSameDayAsToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}
