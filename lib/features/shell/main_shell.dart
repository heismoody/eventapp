import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../dashboard/screens/dashboard_screen.dart';
import '../scanner/screens/scanner_screen.dart';
import '../attendees/screens/attendees_screen.dart';
import '../sms_logs/screens/sms_logs_screen.dart';
import '../settings/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indexFromLocation(String location) {
    if (location.startsWith('/shell/scanner')) return 1;
    if (location.startsWith('/shell/attendees')) return 2;
    if (location.startsWith('/shell/sms')) return 3;
    if (location.startsWith('/shell/settings')) return 4;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        context.go('/shell/dashboard');
      case 1:
        context.go('/shell/scanner');
      case 2:
        context.go('/shell/attendees');
      case 3:
        context.go('/shell/sms');
      case 4:
        context.go('/shell/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Guests'),
          NavigationDestination(icon: Icon(Icons.sms_outlined), selectedIcon: Icon(Icons.sms), label: 'SMS'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
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

class SmsLogsTab extends StatelessWidget {
  const SmsLogsTab({super.key});
  @override
  Widget build(BuildContext context) => const SmsLogsScreen();
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
