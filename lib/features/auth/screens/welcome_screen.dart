import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/language_picker.dart';
import '../../event_request/services/my_request_store.dart';
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
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) subtitle;
  final Color overlayColor;
}

final _slides = [
  _WelcomeSlide(
    imageAsset: 'assets/images/welcome_wedding.png',
    title: (l) => l.welcomeSlide1Title,
    subtitle: (l) => l.welcomeSlide1Body,
    overlayColor: BrandColors.brown,
  ),
  _WelcomeSlide(
    imageAsset: 'assets/images/welcome_celebration.png',
    title: (l) => l.welcomeSlide2Title,
    subtitle: (l) => l.welcomeSlide2Body,
    overlayColor: BrandColors.copper,
  ),
];

/// The first screen. Two ways on: sign in with an account Cardly set up,
/// or ask Cardly to plan an event. Someone who installs the app from the
/// Play Store has no account yet, so signing in can't be the only way.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.skipSplash = false, this.prefill});

  /// Open straight on the sign-in sheet (after logging out, say).
  final bool skipSplash;

  /// Filled into the sign-in sheet, e.g. after choosing a first password.
  final LoginPrefill? prefill;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  static const _sheetAnimationDuration = Duration(milliseconds: 650);

  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _actionsFade;
  late final Animation<double> _scrimFade;

  final PageController _pageController = PageController();
  Timer? _carouselTimer;

  int _currentPage = 0;
  bool _sheetVisible = false;

  @override
  void initState() {
    super.initState();

    _sheetController = AnimationController(
      vsync: this,
      duration: _sheetAnimationDuration,
    );
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _sheetController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _actionsFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _sheetController, curve: const Interval(0, 0.5)),
    );
    _scrimFade = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    if (widget.skipSplash) {
      _sheetVisible = true;
      _sheetController.value = 1.0;
    } else {
      _startCarousel();
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _sheetVisible || !_pageController.hasClients) return;
      _pageController.animateToPage(
        (_currentPage + 1) % _slides.length,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _openSignIn() {
    if (_sheetVisible) return;
    setState(() => _sheetVisible = true);
    _carouselTimer?.cancel();
    _sheetController.forward();
  }

  Future<void> _closeSignIn() async {
    if (!_sheetVisible) return;
    FocusScope.of(context).unfocus();
    await _sheetController.reverse();
    if (!mounted) return;
    setState(() => _sheetVisible = false);
    _startCarousel();
  }

  /// "Plan an event", or "Track my request" once one was sent from this
  /// phone.
  void _planEvent() => context.push(
    ref.read(myRequestProvider) == null ? '/plan-event' : '/plan-event/sent',
  );

  Future<void> _handleLoginSuccess() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !mounted) return;

    final route = await homeRouteAfterSignIn(ref, user);
    if (mounted) context.go(route);
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRequest = ref.watch(myRequestProvider) != null;
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final maxSheetHeight = media.size.height * 0.88;

    return PopScope(
      // Back closes the sign-in sheet first. On the plain welcome screen
      // it leaves the app as usual.
      canPop: !_sheetVisible,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSignIn();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: BrandColors.brownDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              physics: _sheetVisible
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: _slides.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => _WelcomeHeroSlide(
                slide: _slides[index],
                bottomSpace: 300 + media.padding.bottom,
              ),
            ),

            // Dims the photo while the sign-in sheet is up, fading with the
            // sheet, so the form has the focus. Tapping it closes the sheet.
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_sheetVisible,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeSignIn,
                  child: FadeTransition(
                    opacity: _scrimFade,
                    child: ColoredBox(
                      color: BrandColors.brownDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 24,
              right: 24,
              bottom: 24 + media.padding.bottom,
              child: IgnorePointer(
                ignoring: _sheetVisible,
                child: FadeTransition(
                  opacity: _actionsFade,
                  child: _WelcomeActions(
                    pageCount: _slides.length,
                    activePage: _currentPage,
                    onPlanEvent: _planEvent,
                    onSignIn: _openSignIn,
                    tracking: hasRequest,
                  ),
                ),
              ),
            ),

            SlideTransition(
              position: _sheetSlide,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: SizedBox(
                    width: media.size.width,
                    child: Material(
                      elevation: 24,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      color: AppColors.surface,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxSheetHeight),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            12,
                            24,
                            16 + (bottomInset > 0 ? 0 : media.padding.bottom),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                button: true,
                                label: context.l10n.closeSignIn,
                                child: GestureDetector(
                                  onTap: _closeSignIn,
                                  onVerticalDragEnd: (details) {
                                    if ((details.primaryVelocity ?? 0) > 200) {
                                      _closeSignIn();
                                    }
                                  },
                                  child: Container(
                                    width: 64,
                                    height: 20,
                                    alignment: Alignment.center,
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 44,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (widget.prefill?.passwordSaved == true)
                                const _PasswordSavedNote(),
                              LoginForm(
                                compact: true,
                                onSuccess: _handleLoginSuccess,
                                initialIdentifier: widget.prefill?.identifier,
                              ),
                              // One centred line under Sign In, no divider:
                              // the way in for people without an account.
                              const SizedBox(height: 4),
                              Center(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      context.l10n.newToCardly,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppColors.muted),
                                    ),
                                    TextButton(
                                      onPressed: _planEvent,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                      ),
                                      child: Text(
                                        hasRequest
                                            ? context.l10n.trackMyRequest
                                            : context.l10n.planAnEvent,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

            // English or Kiswahili, before anything else is read. Last, so
            // it stays tappable above the sign-in sheet's close area.
            Positioned(
              top: media.padding.top + 12,
              right: 16,
              child: const LanguageSwitch(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({
    required this.pageCount,
    required this.activePage,
    required this.onPlanEvent,
    required this.onSignIn,
    required this.tracking,
  });

  final int pageCount;
  final int activePage;
  final VoidCallback onPlanEvent;
  final VoidCallback onSignIn;

  /// A request was sent from this phone: the first button follows it.
  final bool tracking;

  @override
  Widget build(BuildContext context) {
    const buttonText = TextStyle(fontSize: 17, fontWeight: FontWeight.w700);
    final l10n = context.l10n;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PageIndicators(count: pageCount, activeIndex: activePage),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onPlanEvent,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.onPrimary,
            foregroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(54),
            textStyle: buttonText,
            shape: shape,
          ),
          child: Text(
            tracking ? l10n.trackMyRequest : l10n.planEventWithCardly,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onSignIn,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(54),
            textStyle: buttonText,
            shape: shape,
            side: BorderSide(
              color: AppColors.onPrimary.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Text(l10n.signIn),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.invitedNote,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.onPrimary.withValues(alpha: 0.75),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _WelcomeHeroSlide extends StatelessWidget {
  const _WelcomeHeroSlide({required this.slide, required this.bottomSpace});

  final _WelcomeSlide slide;

  /// Room kept clear at the bottom for the buttons.
  final double bottomSpace;

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
        // Darkens the photo towards the bottom so white text stays readable.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                slide.overlayColor.withValues(alpha: 0.10),
                slide.overlayColor.withValues(alpha: 0.55),
                BrandColors.brownDark.withValues(alpha: 0.96),
                BrandColors.brownDark,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: bottomSpace,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title(context.l10n),
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.subtitle(context.l10n),
                style: TextStyle(
                  color: AppColors.onPrimary.withValues(alpha: 0.88),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({required this.count, required this.activeIndex});

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
            color: active
                ? AppColors.onPrimary
                : AppColors.onPrimary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

/// Above the sign-in form after a new customer chose their password.
class _PasswordSavedNote extends StatelessWidget {
  const _PasswordSavedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.passwordSavedSignIn,
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
