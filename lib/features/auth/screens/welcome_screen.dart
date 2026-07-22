import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../events/providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form.dart';

class _WelcomeSlide {
  const _WelcomeSlide({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.overlayColor,
  });

  final String imageAsset;
  final String title;
  final String subtitle;
  final Color overlayColor;
}

const _slides = [
  _WelcomeSlide(
    imageAsset: 'assets/images/welcome_wedding.png',
    title: 'EventSys',
    subtitle: 'Every guest. Every moment. Perfectly managed.',
    overlayColor: Color(0xFF3D2B1F),
  ),
  _WelcomeSlide(
    imageAsset: 'assets/images/welcome_celebration.png',
    title: 'Celebrate with confidence',
    subtitle: 'Scan guests, track check-ins, and stay in control.',
    overlayColor: Color(0xFF8B6914),
  ),
];

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.skipSplash = false});

  final bool skipSplash;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 2600);
  static const _sheetAnimationDuration = Duration(milliseconds: 900);

  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _heroFade;

  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  Timer? _sheetTimer;

  int _currentPage = 0;
  bool _sheetVisible = false;

  @override
  void initState() {
    super.initState();

    _sheetController = AnimationController(
      vsync: this,
      duration: _sheetAnimationDuration,
    );

    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutCubic,
    ));

    _heroFade = Tween<double>(begin: 1, end: 0.92).animate(CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOut,
    ));

    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _sheetVisible) return;
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });

    if (widget.skipSplash) {
      _sheetVisible = true;
      _sheetController.value = 1.0;
      _carouselTimer?.cancel();
    } else {
      _sheetTimer = Timer(_splashDuration, _raiseLoginSheet);
    }
  }

  void _raiseLoginSheet() {
    if (_sheetVisible || !mounted) return;
    setState(() => _sheetVisible = true);
    _carouselTimer?.cancel();
    _sheetController.forward();
  }

  Future<void> _handleLoginSuccess() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !mounted) return;

    if (user.isEventScoped) {
      await ref
          .read(eventSelectionControllerProvider)
          .initializeOwnedEvent(user.ownedEventId!);
      if (mounted) context.go('/shell/dashboard');
    } else if (mounted) {
      context.go('/events');
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _sheetTimer?.cancel();
    _pageController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _heroFade,
              child: PageView.builder(
                controller: _pageController,
                physics: _sheetVisible
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _WelcomeHeroSlide(slide: _slides[index]);
                },
              ),
            ),
            if (!_sheetVisible)
              Positioned(
                left: 24,
                right: 24,
                bottom: 32,
                child: _PageIndicators(
                  count: _slides.length,
                  activeIndex: _currentPage,
                ),
              ),
            SlideTransition(
              position: _sheetSlide,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width,
                    child: Material(
                      elevation: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      clipBehavior: Clip.antiAlias,
                      color: Colors.white,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxSheetHeight),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 20),
                              LoginForm(
                                compact: true,
                                onSuccess: _handleLoginSuccess,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeroSlide extends StatelessWidget {
  const _WelcomeHeroSlide({required this.slide});

  final _WelcomeSlide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          slide.imageAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                slide.overlayColor.withValues(alpha: 0.15),
                slide.overlayColor.withValues(alpha: 0.55),
                slide.overlayColor.withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 16,
          left: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Text(
              'EventSys Scanner',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 120,
          bottom: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -40,
          top: MediaQuery.sizeOf(context).height * 0.18,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                width: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 8),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
