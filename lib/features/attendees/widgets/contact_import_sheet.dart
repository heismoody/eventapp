import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/connectivity_service.dart';

Future<bool?> showContactImportSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ContactImportSheet(eventId: eventId),
  );
}

class ContactImportSheet extends ConsumerStatefulWidget {
  const ContactImportSheet({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ContactImportSheet> createState() => _ContactImportSheetState();
}

class _ContactImportSheetState extends ConsumerState<ContactImportSheet> {
  List<Contact> _contacts = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _importing = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        setState(() {
          _loading = false;
          _error = 'Contacts permission is required to import guests.';
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      contacts.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      setState(() {
        _contacts = contacts.where((c) => c.phones.isNotEmpty).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Failed to load contacts.';
      });
    }
  }

  List<Contact> get _filteredContacts {
    if (_search.isEmpty) return _contacts;
    final query = _search.toLowerCase();
    return _contacts.where((contact) {
      final nameMatch = contact.displayName.toLowerCase().contains(query);
      final phoneMatch = contact.phones.any((p) => p.number.contains(query));
      return nameMatch || phoneMatch;
    }).toList();
  }

  bool get _allFilteredSelected {
    final filtered = _filteredContacts;
    if (filtered.isEmpty) return false;
    return filtered.every((c) => _selectedIds.contains(c.id));
  }

  void _toggleSelectAll() {
    setState(() {
      final filtered = _filteredContacts;
      if (_allFilteredSelected) {
        for (final contact in filtered) {
          _selectedIds.remove(contact.id);
        }
      } else {
        for (final contact in filtered) {
          _selectedIds.add(contact.id);
        }
      }
    });
  }

  void _toggleContact(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _importSelected() async {
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (!mounted) return;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import requires an internet connection')),
      );
      return;
    }

    final selected = _contacts.where((c) => _selectedIds.contains(c.id)).toList();
    if (selected.isEmpty) return;

    setState(() => _importing = true);

    try {
      final payload = selected
          .map((contact) => {
                'name': contact.displayName.trim(),
                'phone': contact.phones.first.number.trim(),
              })
          .toList();

      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        ApiConfig.attendeesImportPath,
        data: {
          'eventId': widget.eventId,
          'contacts': payload,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final inserted = data['inserted'] as int? ?? 0;
      final skipped = data['skipped'] as int? ?? 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$inserted added, $skipped skipped')),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;
    final selectedCount = _selectedIds.length;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Import contacts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (!_loading && _error == null)
                  TextButton(
                    onPressed: filtered.isEmpty ? null : _toggleSelectAll,
                    child: Text(_allFilteredSelected ? 'Deselect all' : 'Select all'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 24, 0),
              child: Text(
                '${filtered.length} contacts • $selectedCount selected',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadContacts,
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No contacts with phone numbers found',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final contact = filtered[index];
                              final selected = _selectedIds.contains(contact.id);
                              return _ContactSelectCard(
                                initials: _initials(contact.displayName),
                                name: contact.displayName,
                                phone: contact.phones.first.number,
                                selected: selected,
                                onTap: () => _toggleContact(contact.id),
                              );
                            },
                          ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _importing || selectedCount == 0 ? null : _importSelected,
                child: Text(_importing ? 'Importing...' : 'Import ($selectedCount)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSelectCard extends StatelessWidget {
  const _ContactSelectCard({
    required this.initials,
    required this.name,
    required this.phone,
    required this.selected,
    required this.onTap,
  });

  final String initials;
  final String name;
  final String phone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}
