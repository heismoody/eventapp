import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
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
      AppToast.warning('Enter your email and password.');
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

      final token = await ref.read(authServiceProvider).getToken();
      ref.read(authTokenProvider.notifier).state = token;
      ref.read(currentUserProvider.notifier).state = user;
      ref.invalidate(authInitializedProvider);

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
    final checkUrl = AppEnvironment.allowsServerOverride
        ? ' Check the server URL under Advanced.'
        : '';

    if (error is! DioException) {
      // A 200 that isn't the login JSON — usually a URL pointing at some
      // other website.
      return 'Unexpected response from the server.$checkUrl';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return "Can't reach the server. Check your internet connection.$checkUrl";
      case DioExceptionType.badCertificate:
        return "The server's security certificate isn't valid.$checkUrl";
      case DioExceptionType.badResponse:
        return switch (error.response?.statusCode) {
          400 => 'Enter your email and password.',
          401 => 'Wrong email or password, or the account is disabled.',
          403 => "This account isn't allowed to use the Cardly app.",
          404 => "Login service not found on this server.$checkUrl",
          final code? when code >= 500 =>
            'The server had a problem. Please try again shortly.',
          _ => 'Login failed. Please try again.$checkUrl',
        };
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return 'Login failed. Please try again.$checkUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldSpacing = widget.compact ? 12.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to manage your event',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        SizedBox(height: widget.compact ? 16 : 24),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: fieldSpacing),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
        // Production builds are locked to the production server, so there's
        // nothing to configure — the override only exists in dev builds.
        if (AppEnvironment.allowsServerOverride) ...[
          if (_showServerField) ...[
            SizedBox(height: fieldSpacing),
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  setState(() => _showServerField = !_showServerField),
              child: Text(_showServerField ? 'Hide server URL' : 'Advanced'),
            ),
          ),
        ] else
          SizedBox(height: fieldSpacing),
        SizedBox(height: widget.compact ? 16 : 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _login,
            child: Text(_loading ? 'Signing in...' : 'Sign In'),
          ),
        ),
      ],
    );
  }
}
