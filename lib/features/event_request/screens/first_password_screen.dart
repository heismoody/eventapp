import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/l10n.dart';
import '../../auth/services/password_reset_service.dart';
import '../../auth/widgets/code_boxes.dart';
import '../../auth/widgets/login_form.dart';
import '../services/event_request_service.dart';
import '../services/my_request_store.dart';

enum _Step { choose, code, password }

/// "Choose your password" for a new customer whose event is ready.
///
/// 1. Where the code goes: their phone or email, shown masked the way the
///    portal gave them ("•••456"). Nothing is sent before they choose.
/// 2. The 6-digit code, with the other way offered if it doesn't arrive.
/// 3. The password. Then the sign-in sheet opens with their number and the
///    new password filled in, one tap from their event. The password is
///    only passed along in memory, never saved.
class FirstPasswordScreen extends ConsumerStatefulWidget {
  const FirstPasswordScreen({super.key});

  @override
  ConsumerState<FirstPasswordScreen> createState() =>
      _FirstPasswordScreenState();
}

class _FirstPasswordScreenState extends ConsumerState<FirstPasswordScreen> {
  _Step _step = _Step.choose;
  ResetChannel _channel = ResetChannel.sms;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  String _sentTo = '';
  String _resetToken = '';
  String? _signInWith;

  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _codeFocus = FocusNode();

  Timer? _timer;
  int _resendIn = 0;

  PasswordResetService get _service => ref.read(passwordResetServiceProvider);

  @override
  void initState() {
    super.initState();
    final progress = ref.read(myRequestProvider)?.progress;
    if (progress?.smsHint == null && progress?.emailHint != null) {
      _channel = ResetChannel.email;
    }
    // Saved before the portal sent the masked contacts: fetch them.
    if (progress?.smsHint == null && progress?.emailHint == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshHints());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _refreshHints() async {
    final request = ref.read(myRequestProvider);
    if (request == null) return;
    try {
      final progress = await ref
          .read(eventRequestServiceProvider)
          .refreshStatus(request);
      if (!mounted) return;
      setState(() {
        if (progress.smsHint == null && progress.emailHint != null) {
          _channel = ResetChannel.email;
        }
      });
    } catch (_) {
      // The choose step explains there's nothing to send to yet.
    }
  }

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

  Future<void> _send(ResetChannel channel) => _run(() async {
    final request = ref.read(myRequestProvider);
    if (request == null) return;
    final sent = await _service.requestCodeForRequest(request.id, channel);
    if (!mounted) return;
    final progress = request.progress;
    setState(() {
      _channel = channel;
      _sentTo =
          sent.sentTo ??
          (channel == ResetChannel.sms
              ? progress.smsHint
              : progress.emailHint) ??
          '';
      _code.clear();
      _step = _Step.code;
    });
    _startResendTimer(sent.resendAfter);
    _codeFocus.requestFocus();
  });

  Future<void> _verify() => _run(() async {
    final request = ref.read(myRequestProvider);
    if (request == null) return;
    if (_code.text.length != 6) {
      setState(() => _error = context.l10n.enterSixDigitCode);
      return;
    }
    final verified = await _service.verifyCodeForRequest(
      request.id,
      _channel,
      _code.text,
    );
    if (!mounted) return;
    setState(() {
      _resetToken = verified.resetToken;
      _signInWith = verified.signInWith;
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
    final request = ref.read(myRequestProvider);
    await _service.choose(_resetToken, password);
    final identifier =
        _signInWith ??
        (request == null ? '' : CardlyContact.display(request.phone));
    await ref.read(myRequestProvider.notifier).clear();
    if (!mounted) return;
    context.go(
      '/login?skip=1',
      extra: LoginPrefill(
        identifier: identifier,
        password: password,
        passwordSaved: true,
      ),
    );
  });

  void _back() {
    if (_busy) return;
    switch (_step) {
      case _Step.choose:
        context.canPop() ? context.pop() : context.go('/plan-event/sent');
      case _Step.code:
        setState(() {
          _step = _Step.choose;
          _error = null;
        });
      case _Step.password:
        // The code is used up once checked, so start over.
        setState(() {
          _step = _Step.choose;
          _error = null;
          _password.clear();
          _confirm.clear();
        });
    }
  }

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
    final l10n = context.l10n;
    final title = switch (_step) {
      _Step.choose => l10n.choosePasswordButton,
      _Step.code => l10n.enterCodeTitle,
      _Step.password => l10n.newPasswordTitle,
    };

    return PopScope(
      canPop: _step == _Step.choose && !_busy,
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
            tooltip: l10n.back,
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
          titleSpacing: 0,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  _Step.choose => _buildChoose(context),
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

  TextStyle get _strong =>
      TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w700);

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

  Widget _buildChoose(BuildContext context) {
    final l10n = context.l10n;
    final request = ref.watch(myRequestProvider);
    final progress = request?.progress;
    final sms = progress?.smsHint;
    final email = progress?.emailHint;
    final name = request?.firstName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.whereSendCodeTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.whereSendCodeLead(name), style: _lead(context)),
        const SizedBox(height: 24),
        if (sms == null && email == null)
          Text(l10n.eventNotReadyYet, style: _lead(context))
        else
          RadioGroup<ResetChannel>(
            groupValue: _channel,
            onChanged: (value) {
              if (value != null && !_busy) setState(() => _channel = value);
            },
            child: Column(
              children: [
                if (sms != null)
                  _ChannelTile(
                    value: ResetChannel.sms,
                    selected: _channel == ResetChannel.sms,
                    icon: Icons.smartphone_rounded,
                    title: l10n.viaTextMessage,
                    subtitle: spansWith(l10n.viaTextTo, sms, _strong),
                  ),
                if (sms != null && email != null) const SizedBox(height: 12),
                if (email != null)
                  _ChannelTile(
                    value: ResetChannel.email,
                    selected: _channel == ResetChannel.email,
                    icon: Icons.mail_outline_rounded,
                    title: l10n.viaEmail,
                    subtitle: spansWith(l10n.viaEmailTo, email, _strong),
                  ),
              ],
            ),
          ),
        _errorLine(),
        const SizedBox(height: 28),
        if (sms != null || email != null)
          _primary(l10n.sendCode, l10n.sending, () => _send(_channel)),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.cantUseEither, style: TextStyle(color: AppColors.muted)),
            TextButton(
              onPressed: _openWhatsApp,
              child: Text(
                l10n.whatsAppUsLink,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCode(BuildContext context) {
    final l10n = context.l10n;
    final progress = ref.watch(myRequestProvider)?.progress;
    final bySms = _channel == ResetChannel.sms;
    final other = bySms ? progress?.emailHint : progress?.smsHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: _lead(context),
            children: spansWith(
              bySms ? l10n.codeTextedTo : l10n.codeEmailedTo,
              _sentTo,
              _strong,
            ),
          ),
        ),
        const SizedBox(height: 20),
        CodeBoxes(
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
        Align(
          alignment: Alignment.centerLeft,
          child: _resendIn > 0
              ? Text(
                  l10n.resendIn(
                    '${_resendIn ~/ 60}:${(_resendIn % 60).toString().padLeft(2, '0')}',
                  ),
                  style: TextStyle(color: AppColors.muted),
                )
              : TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: _busy ? null : () => _send(_channel),
                  child: Text(
                    l10n.sendCodeAgain,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
        ),
        if (other != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    bySms ? Icons.mail_outline_rounded : Icons.smartphone,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bySms ? l10n.noSmsYet : l10n.noEmailYet),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: _busy
                            ? null
                            : () => _send(
                                bySms ? ResetChannel.email : ResetChannel.sms,
                              ),
                        child: Text(
                          l10n.sendToInstead(other),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _primary(l10n.continueButton, l10n.checking, _verify),
      ],
    );
  }

  Widget _buildPassword(BuildContext context) {
    final l10n = context.l10n;
    final name = ref.read(myRequestProvider)?.firstName ?? '';
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
              children: name.isEmpty
                  ? [TextSpan(text: l10n.chooseNewPassword)]
                  : spansWith(l10n.chooseNewPasswordFor, name, _strong),
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
          _primary(l10n.savePassword, l10n.saving, _save),
        ],
      ),
    );
  }
}

/// One way to receive the code, as a large tappable radio card.
class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ResetChannel value;
  final bool selected;
  final IconData icon;
  final String title;
  final List<InlineSpan> subtitle;

  @override
  Widget build(BuildContext context) {
    final registry = RadioGroup.maybeOf<ResetChannel>(context);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => registry?.onChanged(value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
          child: Row(
            children: [
              Radio<ResetChannel>(value: value),
              const SizedBox(width: 4),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(color: AppColors.muted),
                        children: subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
