import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/session_manager.dart';
import '../../events/providers/event_provider.dart';
import '../../events/services/event_service.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../../scanner/services/sync_service.dart';

const _faqUrl = 'https://cardly.co.tz/#faq';
const _termsUrl = 'https://cardly.co.tz/terms';
const _policyUrl = 'https://cardly.co.tz/privacy';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _serverController;
  late final TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _serverController = TextEditingController(
      text: AppEnvironment.baseUrl(prefs),
    );
    _keyController = TextEditingController();
    ref.read(eventSelectionControllerProvider).loadActiveEventFromPrefs();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveServerUrl() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(ApiConfig.baseUrlKey, _serverController.text.trim());
    if (mounted) {
      AppToast.success('Server URL saved');
    }
  }

  Future<void> _saveKey() async {
    final eventId = ref.read(activeEventIdProvider);
    if (eventId == null) return;

    final key = _keyController.text.trim();
    if (key.length != 64) {
      AppToast.warning('Key must be 64 hex characters');
      return;
    }

    await ref.read(keyVaultProvider).save(eventId, key);
    if (mounted) {
      AppToast.success('Event key saved');
    }
  }

  Future<void> _redownloadKey() async {
    final eventId = ref.read(activeEventIdProvider);
    if (eventId == null) return;

    try {
      final key = await ref.read(eventServiceProvider).fetchEventKey(eventId);
      await ref.read(keyVaultProvider).save(eventId, key);
      if (mounted) {
        AppToast.success('Key re-downloaded');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error('Failed to download key');
      }
    }
  }

  Future<void> _forceSync() async {
    final synced = await ref.read(syncServiceProvider).drainQueue();
    ref.invalidate(pendingSyncCountProvider);
    if (mounted) {
      AppToast.success('Synced $synced check-ins');
    }
  }

  Future<void> _openLink(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      AppToast.error('Could not open the page');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(sessionManagerProvider).handleSessionExpired();
    if (mounted) context.go('/login?skip=1');
  }

  void _showServerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
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
              Text('Server URL', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://your-server.com',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await _saveServerUrl();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showKeySheet() {
    final eventId = ref.read(activeEventIdProvider);
    if (eventId == null) {
      AppToast.info('Select an event first');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
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
                'Encryption key',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste the 64-character key for decrypting guest QR codes.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Event key',
                  hintText: '64-character hex key',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saveKey,
                      child: const Text('Save key'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _redownloadKey,
                      child: const Text('Re-download'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventName = ref.watch(activeEventNameProvider) ?? 'No event selected';
    final user = ref.watch(currentUserProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    final canSwitchEvent = user?.isEventScoped != true;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync now',
            onPressed: _forceSync,
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.sync_outlined),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                if (user != null) ...[
                  _ProfileHeaderCard(
                    user: user,
                    onSeeInfo: () => context.push('/shell/profile'),
                  ),
                  const SizedBox(height: 28),
                ],
                _SettingsSection(
                  items: [
                    _SettingsItem(
                      icon: Icons.event_outlined,
                      label: 'Active event',
                      subtitle: eventName,
                      onTap: canSwitchEvent
                          ? () => context.go('/events')
                          : null,
                    ),
                    _SettingsItem(
                      icon: Icons.cloud_sync_outlined,
                      label: 'Sync check-ins',
                      subtitle: pending > 0
                          ? '$pending waiting to sync'
                          : 'All synced',
                      onTap: _forceSync,
                    ),
                    // Dev builds only — production is locked to its server.
                    if (AppEnvironment.allowsServerOverride)
                      _SettingsItem(
                        icon: Icons.dns_outlined,
                        label: 'Server connection',
                        subtitle: 'Manage API server URL',
                        onTap: _showServerSheet,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsSection(
                  items: [
                    _SettingsItem(
                      icon: Icons.vpn_key_outlined,
                      label: 'Encryption key',
                      subtitle: 'QR code decryption key',
                      onTap: _showKeySheet,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsSection(
                  items: [
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      label: 'FAQ',
                      subtitle: 'Common questions about Cardly',
                      onTap: () => _openLink(_faqUrl),
                    ),
                    _SettingsItem(
                      icon: Icons.description_outlined,
                      label: 'Terms of service',
                      subtitle: 'The rules for using Cardly',
                      onTap: () => _openLink(_termsUrl),
                    ),
                    _SettingsItem(
                      icon: Icons.shield_outlined,
                      label: 'User policy',
                      subtitle: 'How your data is handled',
                      onTap: () => _openLink(_policyUrl),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _AppVersionFooter(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: 18,
                ),
                label: const Text(
                  'Log out',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.user, required this.onSeeInfo});

  final UserModel user;
  final VoidCallback onSeeInfo;

  String get _initials {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onSeeInfo,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the installed version/build — mainly so an update that actually
/// landed is easy to confirm at a glance, without digging through app info.
class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Center(
          child: Text(
            AppEnvironment.isProd
                ? 'Cardly v${info.version} (${info.buildNumber})'
                : 'Cardly v${info.version} (${info.buildNumber}) · ${AppEnvironment.label}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.items});

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Divider(
                height: 1,
                indent: 60,
                endIndent: 16,
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: enabled ? AppColors.onSurface : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
