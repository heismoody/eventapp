import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

typedef LoginSuccessCallback = void Function();

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key, required this.onSuccess, this.compact = false});

  final LoginSuccessCallback onSuccess;
  final bool compact;

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController();
  bool _loading = false;
  bool _showServerField = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _serverController.text = AppEnvironment.baseUrl(prefs);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      AppToast.warning(context.l10n.loginMissingFields);
      return;
    }

    setState(() => _loading = true);

    try {
      if (AppEnvironment.allowsServerOverride) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString(
          ApiConfig.baseUrlKey,
          _serverController.text.trim(),
        );
      }

      final user = await ref
          .read(authServiceProvider)
          .login(_emailController.text.trim(), _passwordController.text);

      await publishSession(ref, user);

      widget.onSuccess();
    } catch (error) {
      if (mounted) AppToast.error(_loginErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Turns a failed login into the actual reason, so the person knows
  /// whether to fix their password, their account, or their connection.
  /// Server-URL hints only appear in dev builds, where the URL is editable.
  String _loginErrorMessage(Object error) {
    final l10n = context.l10n;
    final checkUrl = AppEnvironment.allowsServerOverride
        ? ' ${l10n.loginCheckServerUrl}'
        : '';

    if (error is! DioException) {
      // A 200 that isn't the login JSON — usually a URL pointing at some
      // other website.
      return '${l10n.loginUnexpected}$checkUrl';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return '${l10n.loginUnreachable}$checkUrl';
      case DioExceptionType.badCertificate:
        return '${l10n.loginBadCertificate}$checkUrl';
      case DioExceptionType.badResponse:
        return switch (error.response?.statusCode) {
          400 => l10n.loginMissingFields,
          401 => l10n.loginWrongPassword,
          403 => l10n.loginNotAllowed,
          404 => '${l10n.loginNotFound}$checkUrl',
          final code? when code >= 500 => l10n.serverProblem,
          _ => '${l10n.loginFailed}$checkUrl',
        };
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return '${l10n.loginFailed}$checkUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldSpacing = widget.compact ? 12.0 : 16.0;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.welcomeBack,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.signInSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        SizedBox(height: widget.compact ? 16 : 24),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: l10n.emailOrPhone,
            hintText: l10n.emailOrPhoneHint,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [
            AutofillHints.email,
            AutofillHints.telephoneNumber,
          ],
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: fieldSpacing),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: l10n.password,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _login(),
        ),
        // "Advanced" (dev builds only) on the left, "Forgot password?" on
        // the right. Production builds are locked to the production server,
        // so there's nothing to configure there.
        Row(
          children: [
            if (AppEnvironment.allowsServerOverride)
              TextButton(
                onPressed: () =>
                    setState(() => _showServerField = !_showServerField),
                child: Text(
                  _showServerField ? l10n.hideServerUrl : l10n.advanced,
                ),
              ),
            const Spacer(),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => context.push(
                      '/forgot-password',
                      extra: _emailController.text.trim(),
                    ),
              child: Text(
                l10n.forgotPasswordLink,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        if (AppEnvironment.allowsServerOverride && _showServerField) ...[
          TextField(
            controller: _serverController,
            decoration: InputDecoration(
              labelText: l10n.serverUrl,
              prefixIcon: const Icon(Icons.dns_outlined),
            ),
            keyboardType: TextInputType.url,
          ),
          SizedBox(height: fieldSpacing),
        ],
        SizedBox(height: widget.compact ? 8 : 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _login,
            child: Text(_loading ? l10n.signingIn : l10n.signInButton),
          ),
        ),
      ],
    );
  }
}
