import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../events/providers/event_provider.dart';
import '../../events/services/event_service.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../../scanner/services/sync_service.dart';

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
      text: prefs.getString(ApiConfig.baseUrlKey) ?? ApiConfig.defaultBaseUrl,
    );
    _keyController = TextEditingController();
    loadActiveEventFromPrefs(ref);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URL saved')),
      );
    }
  }

  Future<void> _saveKey() async {
    final eventId = ref.read(activeEventIdProvider);
    if (eventId == null) return;

    final key = _keyController.text.trim();
    if (key.length != 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key must be 64 hex characters')),
      );
      return;
    }

    await ref.read(keyVaultProvider).save(eventId, key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event key saved')),
      );
    }
  }

  Future<void> _redownloadKey() async {
    final eventId = ref.read(activeEventIdProvider);
    if (eventId == null) return;

    try {
      final key = await ref.read(eventServiceProvider).fetchEventKey(eventId);
      await ref.read(keyVaultProvider).save(eventId, key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Key re-downloaded')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download key')),
        );
      }
    }
  }

  Future<void> _forceSync() async {
    final synced = await ref.read(syncServiceProvider).drainQueue();
    ref.invalidate(pendingSyncCountProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $synced check-ins')),
      );
    }
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).logout();
    ref.read(authTokenProvider.notifier).state = null;
    ref.read(currentUserProvider.notifier).state = null;
    ref.invalidate(authInitializedProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final eventName = ref.watch(activeEventNameProvider) ?? 'None';
    final eventId = ref.watch(activeEventIdProvider);
    final user = ref.watch(currentUserProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Active Event'),
              subtitle: Text(eventName),
              trailing: TextButton(
                onPressed: () => context.go('/events'),
                child: const Text('Switch'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Server URL', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _serverController),
          const SizedBox(height: 8),
          FilledButton(onPressed: _saveServerUrl, child: const Text('Save Server URL')),
          const SizedBox(height: 24),
          const Text('Encryption Key', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (eventId != null) ...[
            TextField(
              controller: _keyController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Paste 64-char event key'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: _saveKey, child: const Text('Save Key')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: _redownloadKey, child: const Text('Re-download')),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              title: const Text('Pending Sync'),
              subtitle: Text('$pending check-ins waiting'),
              trailing: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: _forceSync,
              ),
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text(user.name),
                subtitle: Text('${user.email}\n${user.roles.join(', ')}'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
