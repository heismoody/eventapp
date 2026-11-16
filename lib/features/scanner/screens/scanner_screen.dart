import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../../shared/widgets/guest_result_sheet.dart';
import '../../attendees/services/attendee_service.dart';
import '../../events/providers/event_provider.dart';
import '../providers/scanner_provider.dart';
import '../../../l10n/l10n.dart';

/// The camera, opened from the Scan tab. It keeps scanning after each guest,
/// so the door can work through a queue; the close button goes back to the
/// door's numbers.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    // Only QR codes: the scanner doesn't spend time looking for barcodes.
    formats: const [BarcodeFormat.qrCode],
    // Android otherwise analyses 640x480, too little detail for our dense
    // card codes unless they fill the frame. Ignored on iOS, which already
    // uses a high resolution.
    cameraResolution: const Size(1920, 1080),
  );
  bool _processing = false;

  /// Camera zoom, 0 (none) to 1 (the phone's maximum).
  double _zoom = 0;
  double _zoomAtPinchStart = 0;

  /// What the Zoom button switches to: about 2x on most phones.
  static const _buttonZoom = 0.5;
  bool _isOnline = true;
  bool _torchOn = false;

  Timer? _guestListRefresh;
  StreamSubscription<bool>? _connectivity;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivity = ref
        .read(connectivityServiceProvider)
        .onStatusChanged
        .listen((online) {
          if (mounted) setState(() => _isOnline = online);
        });
    // Another gate's entries reach this phone through the guest list, so
    // keep it fresh while scanning.
    _guestListRefresh = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshGuestList(),
    );
    _refreshGuestList();
  }

  Future<void> _refreshGuestList() async {
    final eventId = ref.read(activeEventIdProvider);
    if (eventId == null || !_isOnline) return;
    try {
      await ref.read(attendeeServiceProvider).fetchAttendees(eventId);
      if (mounted) ref.invalidate(doorSummaryProvider(eventId));
    } catch (_) {}
  }

  void _invalidateCheckInViews(String eventId) {
    ref.invalidate(pendingSyncCountProvider);
    ref.invalidate(waitingPeopleProvider(eventId));
    ref.invalidate(recentCheckinsProvider(eventId));
    ref.invalidate(attendeesProvider(eventId));
    ref.invalidate(doorSummaryProvider(eventId));
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

    final scanner = ref.read(scannerProvider);
    final result = await scanner.processScan(value);

    if (mounted) {
      await showGuestResultSheet(
        context,
        result: result,
        onAdmit: (card, count) async {
          final admitted = await scanner.admit(
            card,
            count: count,
            method: 'scan',
          );
          _invalidateCheckInViews(card.eventId);
          return admitted;
        },
      );
    }

    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _setZoom(double value) async {
    final zoom = value.clamp(0.0, 1.0);
    if ((zoom - _zoom).abs() < 0.01) return;
    setState(() => _zoom = zoom);
    try {
      await _controller.setZoomScale(zoom);
    } catch (_) {
      // Camera not running yet; the next gesture tries again.
    }
  }

  Rect _scanFrameRect(Size size) {
    final frameSize = size.width * 0.68;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2 - 24;
    return Rect.fromLTWH(left, top, frameSize, frameSize);
  }

  @override
  void dispose() {
    _guestListRefresh?.cancel();
    _connectivity?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scanRect = _scanFrameRect(size);
    final eventId = ref.watch(activeEventIdProvider);
    final summary = eventId == null
        ? null
        : ref.watch(doorSummaryProvider(eventId)).value;

    return Scaffold(
      backgroundColor: AppColors.scrim,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pinch anywhere on the camera to zoom in on a small code.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (_) => _zoomAtPinchStart = _zoom,
            onScaleUpdate: (details) {
              if (details.pointerCount < 2) return;
              _setZoom(_zoomAtPinchStart + (details.scale - 1) * 0.5);
            },
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.scrim.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _ScannerIconButton(
                          icon: Icons.close,
                          onPressed: () => context.pop(),
                          tooltip: context.l10n.backToDoor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.scanCard,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                summary == null
                                    ? context.l10n.keepsScanning
                                    : context.l10n.peopleInOf(
                                        summary.peopleIn,
                                        summary.peopleExpected,
                                      ),
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ScannerIconButton(
                          icon: _torchOn
                              ? Icons.flashlight_on
                              : Icons.flashlight_off_outlined,
                          active: _torchOn,
                          onPressed: _toggleTorch,
                          tooltip: _torchOn
                              ? context.l10n.flashlightOff
                              : context.l10n.flashlightOn,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.scrim.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _processing
                              ? Icons.hourglass_top
                              : Icons.center_focus_strong_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _processing
                                ? context.l10n.checkingCard
                                : context.l10n.alignQr,
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ZoomButton(
                          zoomed: _zoom > 0,
                          onPressed: () =>
                              _setZoom(_zoom > 0 ? 0 : _buttonZoom),
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
          ? AppColors.accent.withValues(alpha: 0.18)
          : AppColors.chipFill,
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
              color: active ? AppColors.accent : AppColors.onSurface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Switches between no zoom and about 2x, for small codes held at arm's
/// length. Pinching sets any zoom in between.
class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.zoomed, required this.onPressed});

  final bool zoomed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: zoomed,
      label: zoomed ? context.l10n.zoomOut : context.l10n.zoomIn,
      child: Material(
        color: zoomed ? AppColors.primary : AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  zoomed ? Icons.zoom_out : Icons.zoom_in,
                  size: 20,
                  color: zoomed ? AppColors.onPrimary : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  zoomed ? context.l10n.zoomOut : context.l10n.zoom,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: zoomed ? AppColors.onPrimary : AppColors.primary,
                  ),
                ),
              ],
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
        isOnline ? context.l10n.online : context.l10n.offline,
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
  const _ScannerFramePainter({required this.scanRect});

  final Rect scanRect;

  static const _cornerLength = 28.0;
  static const _cornerStroke = 5.0;
  static const _borderRadius = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = AppColors.scrim.withValues(alpha: 0.55);
    final fullScreen = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanRect, const Radius.circular(_borderRadius)),
      );
    final overlay = Path.combine(PathOperation.difference, fullScreen, cutout);
    canvas.drawPath(overlay, overlayPaint);

    final borderPaint = Paint()
      ..color = AppColors.onPrimary.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(_borderRadius)),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = AppColors.onPrimary
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
