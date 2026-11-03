import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Most people one card can admit — matches the server's cap.
const maxPeoplePerCard = 50;

/// How many people a card (or a card type) lets in. Empty is allowed when
/// [hint] is given: the server then uses the card type's default.
class PeopleField extends StatelessWidget {
  const PeopleField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.hint,
    this.minimum = 1,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? hint;

  /// Lowest allowed value — the people already entered, on an edit.
  final int minimum;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return hint == null ? 'Enter how many people' : null;
        final people = int.tryParse(text);
        if (people == null || people < 1 || people > maxPeoplePerCard) {
          return 'From 1 to $maxPeoplePerCard';
        }
        if (people < minimum) {
          return '$minimum already entered — can\'t be fewer';
        }
        return null;
      },
    );
  }
}
