import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// A phone field scoped to Tanzanian mobile numbers: shows a fixed 🇹🇿 +255
/// prefix so the guest only ever types the 9-digit local number after it,
/// instead of being told to type the country code themselves.
class TanzaniaPhoneField extends StatelessWidget {
  const TanzaniaPhoneField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.autofocus = false,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onFieldSubmitted;

  static String? validate(String? value) {
    final digits = (value ?? '').trim();
    if (digits.length != 9) {
      return 'Enter a valid 9-digit number';
    }
    return null;
  }

  /// Combines the entered 9-digit local number with the 255 country code,
  /// ready to send to the backend.
  static String normalize(String value) => '255${value.trim()}';

  /// Strips a previously-stored "255712345678" / "0712345678" number back
  /// down to the bare 9-digit local part, for pre-filling this field when
  /// editing an existing guest.
  static String localPartOf(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255')) return digits.substring(3);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: 'Phone',
        hintText: '712345678',
        prefixText: '🇹🇿 +255  ',
        prefixStyle: const TextStyle(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      validator: validate,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
