import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SmsActionsFab extends StatefulWidget {
  const SmsActionsFab({
    super.key,
    required this.onBuySms,
    required this.onBroadcastSms,
    required this.onIndividualSms,
  });

  final VoidCallback onBuySms;
  final VoidCallback onBroadcastSms;
  final VoidCallback onIndividualSms;

  @override
  State<SmsActionsFab> createState() => _SmsActionsFabState();
}

class _SmsActionsFabState extends State<SmsActionsFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _select(VoidCallback action) {
    _toggle();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SpeedDialAction(
                label: 'Individual SMS',
                icon: Icons.person_outline,
                onTap: () => _select(widget.onIndividualSms),
              ),
              const SizedBox(height: 12),
              _SpeedDialAction(
                label: 'Broadcast SMS',
                icon: Icons.campaign_outlined,
                onTap: () => _select(widget.onBroadcastSms),
              ),
              const SizedBox(height: 12),
              _SpeedDialAction(
                label: 'Buy SMS',
                icon: Icons.payments_outlined,
                onTap: () => _select(widget.onBuySms),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _expanded ? Icons.close : Icons.sms_outlined,
              key: ValueKey(_expanded),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeedDialAction extends StatelessWidget {
  const _SpeedDialAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 3,
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }
}
