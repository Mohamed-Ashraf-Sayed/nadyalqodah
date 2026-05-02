import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable empty state widget for screens with optional pull-to-refresh.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final Future<void> Function()? onRefresh;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: c),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (onRefresh != null) ...[
              const SizedBox(height: 8),
              const Text(
                'اسحب لأسفل للتحديث',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );

    if (onRefresh == null) return body;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: body,
          ),
        ],
      ),
    );
  }
}
