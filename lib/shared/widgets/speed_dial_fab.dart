import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// One labeled action in a [SpeedDialFab]'s menu.
class SpeedDialAction {
  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// A slick speed-dial FAB: a rotating +/× main button that expands into
/// labeled mini-actions with a staggered entrance animation, over a dim
/// backdrop. Meant to be placed as `Positioned.fill` inside a `Stack` that
/// also contains the screen's `Scaffold`, so the backdrop covers the whole
/// screen (header included) when open.
class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({super.key, required this.actions});

  final List<SpeedDialAction> actions;

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _runAction(VoidCallback action) {
    _toggle();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dim backdrop — fills this widget's full-screen bounds (header
        // included) and tap anywhere on it closes the menu.
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.value == 0) return const SizedBox.shrink();
            return GestureDetector(
              onTap: _toggle,
              child: Opacity(
                opacity: _controller.value * 0.5,
                child: Container(color: Colors.black),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = actions.length - 1; i >= 0; i--)
                  _FabMenuItem(
                    action: actions[i],
                    animation: CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        (i / actions.length) * 0.5,
                        1.0,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    onTap: () => _runAction(actions[i].onTap),
                  ),
                const SizedBox(height: 12),
                _FabMainButton(open: _open, onTap: _toggle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FabMainButton extends StatelessWidget {
  const _FabMainButton({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AnimatedRotation(
            turns: open ? 0.125 : 0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.action,
    required this.animation,
    required this.onTap,
  });

  final SpeedDialAction action;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (animation.value == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - animation.value.clamp(0.0, 1.0))),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    action.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      action.icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
