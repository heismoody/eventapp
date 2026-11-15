import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../event_request/services/event_request_service.dart';
import '../providers/auth_provider.dart';
import '../services/password_reset_service.dart';

enum _Step { find, code, password }

/// "Forgot password", in three steps on one screen: where to send the
/// code, the 6-digit code, then the new password. Saving it signs the
/// person straight in.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialIdentifier});

  /// Whatever was typed on the sign-in form, so it isn't typed twice.
  final String? initialIdentifier;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _Step _step = _Step.find;
  bool _busy = false;
  String? _error;

  final _identifier = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _codeFocus = FocusNode();
  bool _obscure = true;

  ResetChannel _channel = ResetChannel.sms;
  String _sentTo = '';
  String _resetToken = '';
  String _name = '';

  Timer? _timer;
  int _resendIn = 0;

  @override
  void initState() {
    super.initState();
    _identifier.text = widget.initialIdentifier ?? '';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _identifier.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  PasswordResetService get _service => ref.read(passwordResetServiceProvider);

  void _startResendTimer(Duration wait) {
    _timer?.cancel();
    setState(() => _resendIn = wait.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      if (_resendIn == 0) timer.cancel();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on PasswordResetException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
      if (error.retryAfter != null) _startResendTimer(error.retryAfter!);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
    final identifier = _identifier.text.trim();
    if (identifier.isEmpty) {
      setState(() => _error = 'Enter your email or phone number.');
      return;
    }
    final sent = await _service.requestCode(identifier);
    if (!mounted) return;
    setState(() {
      _channel = sent.channel;
      _sentTo = identifier;
      _code.clear();
      _step = _Step.code;
    });
    _startResendTimer(sent.resendAfter);
    _codeFocus.requestFocus();
  });

  Future<void> _resend() => _run(() async {
    final sent = await _service.requestCode(_sentTo);
    if (!mounted) return;
    _code.clear();
    _startResendTimer(sent.resendAfter);
    AppToast.success('New code sent.');
  });

  Future<void> _verify() => _run(() async {
    final code = _code.text;
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    final verified = await _service.verifyCode(_sentTo, code);
    if (!mounted) return;
    setState(() {
      _resetToken = verified.resetToken;
      _name = verified.name;
      _step = _Step.password;
    });
  });

  Future<void> _save() => _run(() async {
    final password = _password.text;
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = "The two passwords don't match.");
      return;
    }
    final user = await _service.complete(_resetToken, password);
    if (!mounted) return;
    await publishSession(ref, user);
    final route = await homeRouteAfterSignIn(ref, user);
    if (!mounted) return;
    AppToast.success('Password changed. You are signed in.');
    context.go(route);
  });

  void _back() {
    if (_busy) return;
    switch (_step) {
      case _Step.find:
        context.canPop() ? context.pop() : context.go('/login?skip=1');
      case _Step.code:
        setState(() {
          _step = _Step.find;
          _error = null;
        });
      case _Step.password:
        // The code is used up once checked, so start over.
        setState(() {
          _step = _Step.find;
          _error = null;
          _password.clear();
          _confirm.clear();
        });
    }
  }

  String get _title => switch (_step) {
    _Step.find => 'Forgot password',
    _Step.code => 'Enter code',
    _Step.password => 'New password',
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.find && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
          titleSpacing: 0,
          title: Text(
            _title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        // Pinned to the bottom of the screen, as in the design. The
        // keyboard covers it while typing, which keeps the form clear.
        bottomNavigationBar: _step == _Step.find
            ? const SafeArea(
                minimum: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _HelpCard(),
              )
            : null,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  _Step.find => _buildFind(context),
                  _Step.code => _buildCode(context),
                  _Step.password => _buildPassword(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle? _lead(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyLarge?.copyWith(color: AppColors.muted, height: 1.5);

  Widget _errorLine() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              height: 1.4,
            ),
          ),
        );

  Widget _primary(String label, String busyLabel, VoidCallback onPressed) =>
      SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: _busy ? null : onPressed,
          child: Text(_busy ? busyLabel : label),
        ),
      );

  Widget _buildFind(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Enter the email or phone number on your account. We'll send you "
          'a 6-digit code.',
          style: _lead(context),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _identifier,
          autofocus: _identifier.text.isEmpty,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [
            AutofillHints.email,
            AutofillHints.telephoneNumber,
          ],
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sendCode(),
          decoration: const InputDecoration(
            labelText: 'Email or phone number',
            hintText: 'you@example.com or 0712 345 678',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        _errorLine(),
        const SizedBox(height: 20),
        _primary('Send code', 'Sending...', _sendCode),
      ],
    );
  }

  Widget _buildCode(BuildContext context) {
    final where = _channel == ResetChannel.sms ? 'number' : 'email';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: _lead(context),
            children: [
              const TextSpan(text: 'If '),
              TextSpan(
                text: _sentTo,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text:
                    " is on a Cardly account, we've sent it a 6-digit code. "
                    'It works for 10 minutes.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _CodeBoxes(
          controller: _code,
          focusNode: _codeFocus,
          enabled: !_busy,
          onChanged: () {
            setState(() => _error = null);
            if (_code.text.length == 6) _verify();
          },
        ),
        _errorLine(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _resendIn > 0
                  ? Text(
                      "Didn't get it? Send again in "
                      '${_resendIn ~/ 60}:${(_resendIn % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: AppColors.muted),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: _busy ? null : _resend,
                      child: const Text(
                        'Send the code again',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
            TextButton(
              onPressed: _busy ? null : _back,
              child: Text(
                'Change $where',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _primary('Continue', 'Checking...', _verify),
      ],
    );
  }

  Widget _buildPassword(BuildContext context) {
    final visibility = IconButton(
      tooltip: _obscure ? 'Show password' : 'Hide password',
      onPressed: () => setState(() => _obscure = !_obscure),
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              style: _lead(context),
              children: [
                const TextSpan(text: 'Choose a new password'),
                if (_name.isNotEmpty) ...[
                  const TextSpan(text: ' for '),
                  TextSpan(
                    text: _name,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New password',
              helperText: 'At least 8 characters.',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: visibility,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Type it again',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          _errorLine(),
          const SizedBox(height: 20),
          _primary('Save and sign in', 'Saving...', _save),
        ],
      ),
    );
  }
}

/// Six boxes over one hidden text field, so paste, the keyboard's code
/// suggestion from the SMS, and backspace all just work.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
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
      label: '6-digit code',
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
                            style: const TextStyle(
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

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  Future<void> _openWhatsApp() async {
    final opened = await launchUrl(
      Uri.parse('https://wa.me/${CardlyContact.whatsapp}'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      AppToast.error(
        'WhatsApp us on ${CardlyContact.display(CardlyContact.whatsapp)}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        // Only as tall as its text: the bottom bar slot would let it
        // stretch over the whole screen.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No longer have that number or email?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            "WhatsApp us on ${CardlyContact.display(CardlyContact.whatsapp)} "
            "and we'll help you back in.",
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text(
              'Open WhatsApp',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
