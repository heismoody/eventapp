import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/attendee_service.dart';

String contributionStatusLabel(ContributionPaymentStatus status) {
  return switch (status) {
    ContributionPaymentStatus.paid => 'Fully paid',
    ContributionPaymentStatus.partial => 'Partially paid',
    ContributionPaymentStatus.unpaid => 'Unpaid',
    ContributionPaymentStatus.none => 'No category',
  };
}

Color contributionStatusColor(ContributionPaymentStatus status) {
  return switch (status) {
    ContributionPaymentStatus.paid => AppColors.success,
    ContributionPaymentStatus.partial => AppColors.warning,
    ContributionPaymentStatus.unpaid => AppColors.muted,
    ContributionPaymentStatus.none => AppColors.muted,
  };
}

String guestInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String formatTzsAmount(double amount) {
  final rounded = amount.round();
  final text = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return 'TZS ${buffer.toString()}';
}

String formatCompactAmount(double amount) {
  if (amount >= 1000000) {
    final value = amount / 1000000;
    return value >= 10
        ? '${value.round()}M'
        : '${value.toStringAsFixed(1)}M';
  }
  if (amount >= 1000) {
    final value = amount / 1000;
    return value >= 10
        ? '${value.round()}K'
        : '${value.toStringAsFixed(1)}K';
  }
  return amount.round().toString();
}
