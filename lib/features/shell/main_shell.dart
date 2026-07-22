import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_provider.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../scanner/screens/scanner_screen.dart';
import '../attendees/screens/attendees_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../team/screens/team_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(String location, {required bool showTeamTab}) {
    if (location.startsWith('/shell/scanner')) return 1;
    if (location.startsWith('/shell/attendees')) return 2;
    if (location.startsWith('/shell/team')) return showTeamTab ? 3 : 0;
    if (location.startsWith('/shell/settings')) return showTeamTab ? 4 : 3;
    return 0;
  }

  void _onTap(BuildContext context, int index, {required bool showTeamTab}) {
    switch (index) {
      case 0:
        context.go('/shell/dashboard');
      case 1:
        context.go('/shell/scanner');
      case 2:
        context.go('/shell/attendees');
      case 3:
        context.go(showTeamTab ? '/shell/team' : '/shell/settings');
      case 4:
        context.go('/shell/settings');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final showTeamTab = ref.watch(currentUserProvider)?.isEventOwner ?? false;
    final currentIndex = _indexFromLocation(location, showTeamTab: showTeamTab);

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.qr_code_scanner_outlined),
        selectedIcon: Icon(Icons.qr_code_scanner),
        label: 'Scan',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Guests',
      ),
      if (showTeamTab)
        const NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Team',
        ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTap(context, index, showTeamTab: showTeamTab),
        destinations: destinations,
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

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
