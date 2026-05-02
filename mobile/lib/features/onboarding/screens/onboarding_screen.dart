import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

const String _onboardingSeenKey = 'onboarding_seen_v1';

// Synchronous state. Initialized as `null` (= unknown / loading), then set
// to true/false once SharedPreferences resolves. The router treats `null`
// as "still loading - keep splash" to avoid flashes.
final onboardingSeenProvider = StateProvider<bool?>((ref) => null);

/// Call once at app start to load the persisted value into the provider.
Future<void> initOnboardingState(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool(_onboardingSeenKey) ?? false;
  ref.read(onboardingSeenProvider.notifier).state = seen;
}

Future<void> markOnboardingSeen({WidgetRef? ref}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingSeenKey, true);
  ref?.read(onboardingSeenProvider.notifier).state = true;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  int _page = 0;

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      isLogo: true,
      title: 'مرحبًا بك',
      heading: 'نادي قضاة بني سويف',
      subtitle:
          'تطبيق دليل أعضاء النادي\nيجمع زملاء المهنة في مكان واحد',
    ),
    _OnboardingPage(
      icon: Icons.search_rounded,
      title: 'الدليل والبحث',
      heading: 'تواصل سريع مع الزملاء',
      subtitle: 'ابحث بالاسم، المحكمة، أو التخصص.\nأرقام التواصل بضغطة واحدة.',
    ),
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      title: 'الأحداث والأخبار',
      heading: 'فعاليات النادي معاك',
      subtitle:
          'اجتماعات، دورات، احتفالات، وأخبار النادي\nبتوصلك في وقتها.',
    ),
    _OnboardingPage(
      icon: Icons.lock_rounded,
      title: 'بياناتك محفوظة',
      heading: 'أمان كامل',
      subtitle:
          'بياناتك مشفّرة بالكامل، والتطبيق محصور\nعلى الأعضاء المعتمدين فقط.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingSeen(ref: ref);
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with skip + logo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_page < _pages.length - 1)
                      TextButton(
                        onPressed: _finish,
                        child: const Text(
                          'تخطي',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ],
                ),
              ),
              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _OnboardingPageView(
                    page: _pages[i],
                    isActive: i == _page,
                  ),
                ),
              ),
              // Indicators + Next/Start
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: active ? 28 : 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _next,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _page == _pages.length - 1
                                  ? 'يلا نبدأ'
                                  : 'التالي',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _page == _pages.length - 1
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward_ios,
                              size: 16,
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
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData? icon;
  final bool isLogo;
  final String title;
  final String heading;
  final String subtitle;
  const _OnboardingPage({
    this.icon,
    this.isLogo = false,
    required this.title,
    required this.heading,
    required this.subtitle,
  });
}

class _OnboardingPageView extends StatefulWidget {
  final _OnboardingPage page;
  final bool isActive;
  const _OnboardingPageView({required this.page, required this.isActive});

  @override
  State<_OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends State<_OnboardingPageView>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0, // start at 1 so the page is visible immediately
    );
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    // Replay entry animation when active
    if (widget.isActive) {
      _enter
        ..reset()
        ..forward();
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingPageView old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _enter
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual with entry + idle animations
          AnimatedBuilder(
            animation: Listenable.merge([_enter, _idle]),
            builder: (_, child) {
              final t = Curves.easeOutCubic.transform(_enter.value);
              final idleT = _idle.value;
              // Scale 0.85 -> 1.0 (subtle, never 0)
              final scale = 0.85 + 0.15 * t;
              // Subtle floating: ±4px
              final dy = (idleT - 0.5) * 8;
              return Opacity(
                opacity: 0.4 + 0.6 * t,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
            child: widget.page.isLogo
                ? _LogoVisual(idle: _idle)
                : _IconCard(icon: widget.page.icon!, idle: _idle),
          ),
          const SizedBox(height: 44),
          // Animated text - slide up + fade
          _AnimatedSlideFade(
            controller: _enter,
            delay: 0.2,
            child: Text(
              widget.page.title,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _AnimatedSlideFade(
            controller: _enter,
            delay: 0.3,
            child: Text(
              widget.page.heading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _AnimatedSlideFade(
            controller: _enter,
            delay: 0.4,
            child: Text(
              widget.page.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide-up + fade animation with optional start delay (0..1 of controller).
class _AnimatedSlideFade extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;
  const _AnimatedSlideFade({
    required this.controller,
    required this.child,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, c) {
        final raw = ((controller.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        final t = Curves.easeOutCubic.transform(raw);
        return Opacity(
          // Keep a minimum visibility to avoid totally hidden text on first frame
          opacity: 0.3 + 0.7 * t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

// Centered logo with subtle breathing glow only (no ring)
class _LogoVisual extends StatelessWidget {
  final AnimationController idle;
  const _LogoVisual({required this.idle});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idle,
      builder: (_, __) {
        final t = idle.value;
        final glowAlpha = 0.18 + 0.18 * t;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: glowAlpha),
                blurRadius: 60,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            width: 130,
            height: 130,
          ),
        );
      },
    );
  }
}

// Squircle icon card with subtle tilt + shimmer driven by idle controller
class _IconCard extends StatelessWidget {
  final IconData icon;
  final AnimationController idle;
  const _IconCard({required this.icon, required this.idle});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idle,
      builder: (_, __) {
        final t = idle.value; // 0..1 reverse
        // Gentle tilt: ±2 degrees
        final tilt = (t - 0.5) * 0.07;
        // Shimmer position across icon
        final shimmer = (idle.value * 2) - 1; // -1..1

        return Transform.rotate(
          angle: tilt,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0BB6A),
                  Color(0xFFB8893B),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4 + 0.15 * t),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Stack(
                children: [
                  // Shimmer streak crossing diagonally
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(shimmer * 140, 0),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.18),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.35, 0.5, 0.65],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Inner highlight (top-left)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.6, -0.7),
                          radius: 0.9,
                          colors: [
                            Colors.white.withValues(alpha: 0.32),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Icon with subtle scale pulse
                  Center(
                    child: Transform.scale(
                      scale: 1.0 + 0.04 * t,
                      child: Icon(
                        icon,
                        size: 60,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0x55000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
