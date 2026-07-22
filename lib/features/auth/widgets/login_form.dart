import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

typedef LoginSuccessCallback = void Function();

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({
    super.key,
    required this.onSuccess,
    this.compact = false,
  });

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
  String? _error;
  bool _showServerField = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _serverController.text =
        prefs.getString(ApiConfig.baseUrlKey) ?? ApiConfig.defaultBaseUrl;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(ApiConfig.baseUrlKey, _serverController.text.trim());

      final user = await ref.read(authServiceProvider).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      final token = await ref.read(authServiceProvider).getToken();
      ref.read(authTokenProvider.notifier).state = token;
      ref.read(currentUserProvider.notifier).state = user;
      ref.invalidate(authInitializedProvider);

      widget.onSuccess();
    } catch (_) {
      setState(() => _error = 'Login failed. Check credentials and server URL.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
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
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _login(),
        ),
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
            onPressed: () => setState(() => _showServerField = !_showServerField),
            child: Text(_showServerField ? 'Hide server URL' : 'Advanced'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
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
