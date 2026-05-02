import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_stats.dart';
import '../../../data/providers/providers.dart';

final statsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  return ref.read(adminRepositoryProvider).stats();
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذر تحميل البيانات')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.refresh(statsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section('الأعضاء'),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.verified_user_outlined,
                    color: AppColors.success,
                    label: 'الأعضاء المعتمدين',
                    value: '${stats.approved}',
                  ),
                  _StatCard(
                    icon: Icons.pending_actions,
                    color: AppColors.warning,
                    label: 'في انتظار الموافقة',
                    value: '${stats.pending}',
                  ),
                  _StatCard(
                    icon: Icons.trending_up,
                    color: AppColors.primary,
                    label: 'انضموا آخر 30 يوم',
                    value: '${stats.newLast30Days}',
                  ),
                  _StatCard(
                    icon: Icons.admin_panel_settings_outlined,
                    color: AppColors.accent,
                    label: 'الأدمن',
                    value: '${stats.admins}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _section('المحتوى'),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  _StatCard(
                    icon: Icons.article_outlined,
                    color: AppColors.primary,
                    label: 'أخبار',
                    value: '${stats.newsCount}',
                    compact: true,
                  ),
                  _StatCard(
                    icon: Icons.description_outlined,
                    color: AppColors.danger,
                    label: 'تعاقدات',
                    value: '${stats.contractsCount}',
                    compact: true,
                  ),
                  _StatCard(
                    icon: Icons.event_outlined,
                    color: AppColors.accent,
                    label: 'أحداث قادمة',
                    value: '${stats.upcomingEventsCount}',
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _section('الاقتراحات والشكاوى'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.feedback_outlined,
                      color: AppColors.warning,
                      label: 'مفتوحة',
                      value: '${stats.openSuggestions}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.history,
                      color: AppColors.textSecondary,
                      label: 'الإجمالي',
                      value: '${stats.totalSuggestions}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (stats.byGovernorate.isNotEmpty) ...[
                _section('التوزيع حسب المحافظة'),
                const SizedBox(height: 8),
                _DistributionList(
                  entries: stats.byGovernorate,
                  total: stats.approved,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
              ],
              if (stats.byRank.isNotEmpty) ...[
                _section('التوزيع حسب الدرجة الوظيفية'),
                const SizedBox(height: 8),
                _DistributionList(
                  entries: stats.byRank,
                  total: stats.approved,
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool compact;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: compact ? 18 : 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionList extends StatelessWidget {
  final List<DistEntry> entries;
  final int total;
  final Color color;

  const _DistributionList({
    required this.entries,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = entries.isEmpty ? 1 : entries.first.count;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: entries.map((e) {
          final percent = total == 0 ? 0.0 : e.count / total;
          final barWidth = e.count / maxCount;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${e.count}  (${(percent * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: color.withValues(alpha: 0.12),
                      ),
                      FractionallySizedBox(
                        widthFactor: barWidth,
                        child: Container(
                          height: 6,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
