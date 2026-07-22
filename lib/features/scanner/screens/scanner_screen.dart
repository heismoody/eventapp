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
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _processing = false;
  bool _isOnline = true;
  bool _torchOn = false;

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

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) {
      setState(() => _torchOn = _controller.torchEnabled);
    }
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

  Rect _scanFrameRect(Size size) {
    final frameSize = size.width * 0.68;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2 - 24;
    return Rect.fromLTWH(left, top, frameSize, frameSize);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scanRect = _scanFrameRect(size);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          CustomPaint(
            painter: _ScannerFramePainter(scanRect: scanRect),
            size: size,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'Check in guests instantly',
                                style: TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _ScannerIconButton(
                          icon: _torchOn ? Icons.flashlight_on : Icons.flashlight_off_outlined,
                          active: _torchOn,
                          onPressed: _toggleTorch,
                          tooltip: _torchOn ? 'Turn off flashlight' : 'Turn on flashlight',
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(isOnline: _isOnline),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _processing ? Icons.hourglass_top : Icons.center_focus_strong_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _processing
                                ? 'Processing guest check-in...'
                                : 'Align the QR code inside the frame',
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _ScannerIconButton extends StatelessWidget {
  const _ScannerIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.gold.withValues(alpha: 0.18)
          : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: active ? AppColors.gold : AppColors.onSurface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter({
    required this.scanRect,
  });

  final Rect scanRect;

  static const _cornerLength = 28.0;
  static const _cornerStroke = 5.0;
  static const _borderRadius = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final fullScreen = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanRect, const Radius.circular(_borderRadius)),
      );
    final overlay = Path.combine(PathOperation.difference, fullScreen, cutout);
    canvas.drawPath(overlay, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(_borderRadius)),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    _drawCorner(canvas, cornerPaint, scanRect.topLeft, 1, 1);
    _drawCorner(canvas, cornerPaint, scanRect.topRight, -1, 1);
    _drawCorner(canvas, cornerPaint, scanRect.bottomLeft, 1, -1);
    _drawCorner(canvas, cornerPaint, scanRect.bottomRight, -1, -1);
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    Offset origin,
    int xDirection,
    int yDirection,
  ) {
    final horizontalEnd = origin + Offset(_cornerLength * xDirection, 0);
    final verticalEnd = origin + Offset(0, _cornerLength * yDirection);

    canvas.drawLine(origin, horizontalEnd, paint);
    canvas.drawLine(origin, verticalEnd, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) {
    return oldDelegate.scanRect != scanRect;
  }
}
