import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n.dart';

/// Six boxes over one hidden text field, so paste, the keyboard's code
/// suggestion from the SMS, and backspace all just work.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.sixDigitCode,
      child: SizedBox(
        height: 60,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([controller, focusNode]),
              builder: (context, _) {
                final text = controller.text;
                return Row(
                  children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  focusNode.hasFocus &&
                                      i == text.length.clamp(0, 5)
                                  ? AppColors.primary
                                  : AppColors.border,
                              width:
                                  focusNode.hasFocus &&
                                      i == text.length.clamp(0, 5)
                                  ? 2
                                  : 1,
                            ),
                          ),
                          child: Text(
                            i < text.length ? text[i] : '',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
