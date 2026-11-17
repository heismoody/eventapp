import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/l10n.dart';
import '../../event_request/services/event_request_service.dart';
import '../../event_request/services/my_request_store.dart';
import '../widgets/login_form.dart';
import '../providers/auth_provider.dart';
import '../services/password_reset_service.dart';

enum _Step { find, code, password }

/// "Forgot password", in three steps on one screen: where to send the
/// code, the 6-digit code, then the new password. Saving it signs the
/// person straight in.
///
/// With [firstPassword], it's a new customer whose event is ready: the
/// code goes straight to the phone on their request, and saving takes
/// them to the sign-in sheet with that number filled in.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialIdentifier,
    this.firstPassword = false,
  });

  /// Whatever was typed on the sign-in form, so it isn't typed twice.
  final String? initialIdentifier;
  final bool firstPassword;

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
    _identifier.text = widget.initialIdentifier == null
        ? ''
        : widget.firstPassword
        ? CardlyContact.display(widget.initialIdentifier!)
        : widget.initialIdentifier!;
    if (widget.firstPassword && _identifier.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
    }
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
      if (mounted) setState(() => _error = context.l10n.genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
    final identifier = _identifier.text.trim();
    if (identifier.isEmpty) {
      setState(() => _error = context.l10n.enterIdentifier);
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
    AppToast.success(context.l10n.newCodeSent);
  });

  Future<void> _verify() => _run(() async {
    final code = _code.text;
    if (code.length != 6) {
      setState(() => _error = context.l10n.enterSixDigitCode);
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
      setState(() => _error = context.l10n.passwordTooShort);
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = context.l10n.passwordsDontMatch);
      return;
    }
    if (widget.firstPassword) {
      await _service.choose(_resetToken, password);
      await ref.read(myRequestProvider.notifier).clear();
      if (!mounted) return;
      context.go(
        '/login?skip=1',
        extra: LoginPrefill(identifier: _sentTo, passwordSaved: true),
      );
      return;
    }
    final user = await _service.complete(_resetToken, password);
    if (!mounted) return;
    await publishSession(ref, user);
    final route = await homeRouteAfterSignIn(ref, user);
    if (!mounted) return;
    AppToast.success(context.l10n.passwordChangedSignedIn);
    context.go(route);
  });

  void _back() {
    if (_busy) return;
    switch (_step) {
      case _Step.find:
        context.canPop() ? context.pop() : context.go('/login?skip=1');
      case _Step.code when widget.firstPassword:
        // The number comes from their request: nothing to change here.
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
    _Step.find when widget.firstPassword => context.l10n.choosePasswordButton,
    _Step.find => context.l10n.forgotTitle,
    _Step.code => context.l10n.enterCodeTitle,
    _Step.password => context.l10n.newPasswordTitle,
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
            tooltip: context.l10n.back,
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
        Text(context.l10n.forgotLead, style: _lead(context)),
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
          decoration: InputDecoration(
            labelText: context.l10n.emailOrPhone,
            hintText: context.l10n.emailOrPhoneHint,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        _errorLine(),
        const SizedBox(height: 20),
        _primary(context.l10n.sendCode, context.l10n.sending, _sendCode),
      ],
    );
  }

  Widget _buildCode(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: _lead(context),
            children: spansWith(
              l10n.codeSentLead,
              _sentTo,
              TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
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
                      l10n.resendIn(
                        '${_resendIn ~/ 60}:${(_resendIn % 60).toString().padLeft(2, '0')}',
                      ),
                      style: TextStyle(color: AppColors.muted),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: _busy ? null : _resend,
                      child: Text(
                        l10n.sendCodeAgain,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
            if (!widget.firstPassword)
              TextButton(
                onPressed: _busy ? null : _back,
                child: Text(
                  _channel == ResetChannel.sms
                      ? l10n.changeNumber
                      : l10n.changeEmail,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _primary(l10n.continueButton, l10n.checking, _verify),
      ],
    );
  }

  Widget _buildPassword(BuildContext context) {
    final l10n = context.l10n;
    final visibility = IconButton(
      tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
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
              children: _name.isEmpty
                  ? [TextSpan(text: l10n.chooseNewPassword)]
                  : spansWith(
                      l10n.chooseNewPasswordFor,
                      _name,
                      TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
              labelText: l10n.newPasswordLabel,
              helperText: l10n.passwordHelper,
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
            decoration: InputDecoration(
              labelText: l10n.typeItAgain,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          _errorLine(),
          const SizedBox(height: 20),
          _primary(
            widget.firstPassword ? l10n.savePassword : l10n.saveAndSignIn,
            l10n.saving,
            _save,
          ),
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

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  Future<void> _openWhatsApp() async {
    final opened = await launchUrl(
      Uri.parse('https://wa.me/${CardlyContact.whatsapp}'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      AppToast.error(
        appL10n.whatsAppUsOn(CardlyContact.display(CardlyContact.whatsapp)),
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
          Text(
            context.l10n.lostAccessTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.lostAccessBody(
              CardlyContact.display(CardlyContact.whatsapp),
            ),
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: Text(
              context.l10n.openWhatsApp,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
