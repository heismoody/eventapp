import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_provider.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../scanner/screens/scanner_screen.dart';
import '../attendees/screens/attendees_screen.dart';
import '../contributions/screens/contributions_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../team/screens/team_screen.dart';
import '../update/services/update_service.dart';
import '../update/widgets/update_dialog.dart';

class _ShellTab {
  const _ShellTab({
    required this.route,
    required this.prefix,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String route;
  final String prefix;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  List<_ShellTab> _tabs({
    required bool showOwnerTabs,
    required bool showScanner,
  }) {
    return [
      const _ShellTab(
        route: '/shell/dashboard',
        prefix: '/shell/dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
      ),
      if (showScanner)
        const _ShellTab(
          route: '/shell/scanner',
          prefix: '/shell/scanner',
          icon: Icons.qr_code_scanner_outlined,
          selectedIcon: Icons.qr_code_scanner,
          label: 'Scan',
        ),
      const _ShellTab(
        route: '/shell/attendees',
        prefix: '/shell/attendees',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: 'Guests',
      ),
      if (showOwnerTabs)
        const _ShellTab(
          route: '/shell/contributions',
          prefix: '/shell/contributions',
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments,
          label: 'Contributions',
        ),
      if (showOwnerTabs)
        const _ShellTab(
          route: '/shell/team',
          prefix: '/shell/team',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          label: 'Team',
        ),
      const _ShellTab(
        route: '/shell/settings',
        prefix: '/shell/settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One-shot: fires only when the check actually resolves to an update,
    // not on every rebuild — safe to call unconditionally here.
    ref.listen(appUpdateProvider, (previous, next) {
      next.whenData((release) {
        if (release != null) showUpdateDialog(context, release);
      });
    });

    final location = GoRouterState.of(context).uri.toString();
    final user = ref.watch(currentUserProvider);
    final showOwnerTabs = user?.isEventOwner ?? false;
    final showScanner = user?.roles.contains('scanner') ?? false;
    final tabs = _tabs(showOwnerTabs: showOwnerTabs, showScanner: showScanner);

    final matched = tabs.indexWhere((tab) => location.startsWith(tab.prefix));
    final currentIndex = matched < 0 ? 0 : matched;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(tabs[index].route),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) => const DashboardScreen();
}

class ScannerTab extends StatelessWidget {
  const ScannerTab({super.key});
  @override
  Widget build(BuildContext context) => const ScannerScreen();
}

class AttendeesTab extends StatelessWidget {
  const AttendeesTab({super.key});
  @override
  Widget build(BuildContext context) => const AttendeesScreen();
}

class TeamTab extends StatelessWidget {
  const TeamTab({super.key});
  @override
  Widget build(BuildContext context) => const TeamScreen();
}

class ContributionsTab extends StatelessWidget {
  const ContributionsTab({super.key});
  @override
  Widget build(BuildContext context) => const ContributionsScreen();
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
