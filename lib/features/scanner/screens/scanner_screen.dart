import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../../shared/widgets/guest_result_sheet.dart';
import '../../events/providers/event_provider.dart';
import '../providers/scanner_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _controller = MobileScannerController();
  bool _processing = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    ref.read(connectivityServiceProvider).onStatusChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    setState(() => _processing = true);
    HapticFeedback.mediumImpact();

    final result = await ref.read(scannerProvider).processScan(value);

    ref.invalidate(pendingSyncCountProvider);
    final eventId = ref.read(activeEventIdProvider);
    if (eventId != null) {
      ref.invalidate(checkinCountProvider(eventId));
      ref.invalidate(recentCheckinsProvider(eventId));
    }

    if (mounted) {
      await showGuestResultSheet(context, result: result);
    }

    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _processing = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scan QR Code', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Chip(
                        label: Text(_isOnline ? 'Online' : 'Offline — queuing',
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: _isOnline
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.warning.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _processing ? 'Processing...' : 'Point camera at guest QR code',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
