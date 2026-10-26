import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/tanzania_phone_field.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _originalPhone = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    try {
      final account = await ref.read(profileServiceProvider).fetchProfile();
      if (!mounted) return;
      _nameController.text = account.name;
      _emailController.text = account.email;
      _originalPhone = TanzaniaPhoneField.localPartOf(account.phone ?? '');
      _phoneController.text = _originalPhone;
    } catch (_) {
      // Keep whatever the signed-in user already had locally.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phoneLocal = _phoneController.text.trim();
    final phoneChanged = phoneLocal != _originalPhone && phoneLocal.isNotEmpty;

    setState(() => _saving = true);
    try {
      final account = await ref
          .read(profileServiceProvider)
          .updateProfile(
            name: name,
            email: email,
            phone: phoneChanged
                ? TanzaniaPhoneField.normalize(phoneLocal)
                : null,
          );

      final current = ref.read(currentUserProvider);
      if (current != null) {
        ref.read(currentUserProvider.notifier).state = UserModel(
          id: current.id,
          name: account.name,
          email: account.email,
          roles: current.roles,
          ownedEventId: current.ownedEventId,
        );
      }
      _originalPhone = TanzaniaPhoneField.localPartOf(account.phone ?? '');
      if (mounted) AppToast.success('Profile updated');
    } catch (_) {
      if (mounted) AppToast.error('Could not update profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openChangePassword() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ChangePasswordSheet(
        onSubmit: (current, next) => ref
            .read(profileServiceProvider)
            .changePassword(currentPassword: current, newPassword: next),
      ),
    );
  }

  String get _initials {
    final parts = _nameController.text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              enabled: !_saving,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TanzaniaPhoneField(
                              controller: _phoneController,
                              enabled: !_saving,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              enabled: !_saving,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                              validator: _validateEmail,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _saving ? null : _openChangePassword,
                            style: OutlinedButton.styleFrom(
                              shape: const StadiumBorder(),
                              side: const BorderSide(color: AppColors.border),
                              foregroundColor: AppColors.onSurface,
                            ),
                            child: const Text(
                              'Change password',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              _saving ? 'Saving...' : 'Save changes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.onSubmit});

  final Future<void> Function(String current, String next) onSubmit;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_currentController.text, _newController.text);
      if (mounted) {
        Navigator.pop(context);
        AppToast.success('Password changed');
      }
    } catch (_) {
      if (mounted) AppToast.error('Could not change password');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Enter your current password' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                helperText: 'At least 8 characters',
              ),
              validator: (value) =>
                  (value ?? '').length < 8 ? 'Use at least 8 characters' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
              validator: (value) => value != _newController.text
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Saving...' : 'Update password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
