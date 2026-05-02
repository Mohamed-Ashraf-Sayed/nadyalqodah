import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_controller.dart';
import 'email_verification_screen.dart';

class AwaitingApprovalScreen extends ConsumerStatefulWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  ConsumerState<AwaitingApprovalScreen> createState() => _AwaitingApprovalScreenState();
}

class _AwaitingApprovalScreenState extends ConsumerState<AwaitingApprovalScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.surface,
              AppColors.surface,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _AnimatedHourglass(
                  rotationController: _rotationCtrl,
                  pulseController: _pulseCtrl,
                ),
                const SizedBox(height: 24),
                const Text(
                  'طلبك قيد المراجعة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'إدارة النادي بتراجع طلبك دلوقتي\nهتوصلك رسالة بمجرد الموافقة',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.6,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Email card
                if (state.user?.email != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.email_outlined,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'حساب التسجيل',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.user!.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Email verification CTA (if not verified)
                if (state.user != null && !state.user!.emailVerified) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmailVerificationScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_unread_outlined,
                              color: AppColors.warning, size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تأكد من بريدك الإلكتروني',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'بعتنالك كود تأكيد، اضغط هنا لإدخاله',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left,
                              color: AppColors.warning),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Status timeline
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const _StatusStep(
                        icon: Icons.check,
                        label: 'تم استلام الطلب',
                        subtitle: 'بياناتك متسجلة',
                        isDone: true,
                        isLast: false,
                      ),
                      _StatusStep(
                        icon: Icons.hourglass_top,
                        label: 'مراجعة من الإدارة',
                        subtitle: 'جاري الفحص الآن',
                        isDone: false,
                        isCurrent: true,
                        pulseController: _pulseCtrl,
                        isLast: false,
                      ),
                      const _StatusStep(
                        icon: Icons.notifications_active_outlined,
                        label: 'إخطار بالنتيجة',
                        subtitle: 'هتوصلك رسالة',
                        isDone: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Refresh button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('تحديث الحالة'),
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).refreshMe(),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text(
                    'تسجيل خروج',
                    style: TextStyle(color: AppColors.danger),
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

class _AnimatedHourglass extends StatelessWidget {
  final AnimationController rotationController;
  final AnimationController pulseController;

  const _AnimatedHourglass({
    required this.rotationController,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer expanding ring
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, __) {
              final t = pulseController.value;
              return Container(
                width: 130 + (t * 36),
                height: 130 + (t * 36),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22 * (1 - t)),
                    width: 2.5,
                  ),
                ),
              );
            },
          ),
          // Middle expanding ring (offset phase)
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, __) {
              final t = (pulseController.value + 0.5) % 1;
              return Container(
                width: 120 + (t * 28),
                height: 120 + (t * 28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.38 * (1 - t)),
                    width: 2.5,
                  ),
                ),
              );
            },
          ),
          // Gold gradient solid disc with glow
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0BB6A),
                  Color(0xFFB8893B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          // Inner highlight ring
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.9,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Rotating hourglass (white on gold)
          AnimatedBuilder(
            animation: rotationController,
            builder: (_, __) {
              final progress = rotationController.value;
              double angle;
              if (progress < 0.4) {
                angle = 0;
              } else if (progress < 0.5) {
                final t = (progress - 0.4) / 0.1;
                angle = t * 3.14159;
              } else if (progress < 0.9) {
                angle = 3.14159;
              } else {
                final t = (progress - 0.9) / 0.1;
                angle = 3.14159 + t * 3.14159;
              }
              return Transform.rotate(
                angle: angle,
                child: const Icon(
                  Icons.hourglass_top,
                  size: 56,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color(0x55000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final AnimationController? pulseController;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDone,
    this.isCurrent = false,
    required this.isLast,
    this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDone ? AppColors.success : (isCurrent ? AppColors.accent : AppColors.textSecondary);

    Widget circle = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: activeColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Icon(icon, color: activeColor, size: 18),
    );

    if (isCurrent && pulseController != null) {
      circle = AnimatedBuilder(
        animation: pulseController!,
        builder: (_, child) {
          final scale = 1.0 + (pulseController!.value * 0.1);
          return Transform.scale(scale: scale, child: child);
        },
        child: circle,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              circle,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDone || isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
