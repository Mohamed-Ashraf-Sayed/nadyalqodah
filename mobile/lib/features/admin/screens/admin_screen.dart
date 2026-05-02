import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';
import '../../../data/repositories/admin_repository.dart';

final pendingProvider = FutureProvider.autoDispose<List<PendingRequest>>((ref) {
  return ref.read(adminRepositoryProvider).pending();
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingProvider);
    final pendingCount =
        async.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'إشعار جماعي',
            onPressed: () => _showBroadcast(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(pendingProvider),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _AdminHeader(pendingCount: pendingCount),
            const SizedBox(height: 16),
            _SectionTitle(title: 'الإجراءات السريعة'),
            const SizedBox(height: 8),
            _ActionsGrid(
              onApprovals: null, // current screen
              pendingCount: pendingCount,
              onStats: () => context.push('/admin/stats'),
              onSuggestions: () => context.push('/suggestions'),
              onAddEvent: () => context.push('/events/new'),
              onAddNews: () => context.push('/news/new'),
              onAddContract: () => context.push('/contracts/new'),
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'طلبات تنتظر الموافقة'),
            const SizedBox(height: 8),
            _PendingList(async: async, ref: ref),
          ],
        ),
      ),
    );
  }

  Future<void> _showBroadcast(BuildContext ctx, WidgetRef ref) async {
    final result = await showDialog<({String title, String body})?>(
      context: ctx,
      builder: (c) => const _BroadcastDialog(),
    );
    if (result == null) return;
    await ref.read(adminRepositoryProvider).broadcast(
          title: result.title,
          body: result.body,
        );
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('تم الإرسال')),
      );
    }
  }
}

// --- Header card ---

class _AdminHeader extends StatelessWidget {
  final int pendingCount;
  const _AdminHeader({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لوحة الإدارة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingCount > 0
                      ? '$pendingCount ${pendingCount == 1 ? "طلب" : "طلبات"} في الانتظار'
                      : 'لا توجد طلبات معلقة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Quick actions grid ---

class _ActionsGrid extends StatelessWidget {
  final VoidCallback? onApprovals;
  final int pendingCount;
  final VoidCallback onStats;
  final VoidCallback onSuggestions;
  final VoidCallback onAddEvent;
  final VoidCallback onAddNews;
  final VoidCallback onAddContract;

  const _ActionsGrid({
    required this.onApprovals,
    required this.pendingCount,
    required this.onStats,
    required this.onSuggestions,
    required this.onAddEvent,
    required this.onAddNews,
    required this.onAddContract,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _ActionTile(
          icon: Icons.bar_chart_outlined,
          label: 'الإحصائيات',
          onTap: onStats,
        ),
        _ActionTile(
          icon: Icons.feedback_outlined,
          label: 'الاقتراحات',
          onTap: onSuggestions,
        ),
        _ActionTile(
          icon: Icons.event_outlined,
          label: 'إضافة حدث',
          onTap: onAddEvent,
        ),
        _ActionTile(
          icon: Icons.article_outlined,
          label: 'نشر خبر',
          onTap: onAddNews,
        ),
        _ActionTile(
          icon: Icons.upload_file_outlined,
          label: 'رفع تعاقد',
          onTap: onAddContract,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Pending requests list ---

class _PendingList extends StatelessWidget {
  final AsyncValue<List<PendingRequest>> async;
  final WidgetRef ref;
  const _PendingList({required this.async, required this.ref});

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('تعذر التحميل')),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppColors.success),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'مفيش طلبات معلقة',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: items
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PendingCard(request: r, ref: ref),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PendingRequest request;
  final WidgetRef ref;
  const _PendingCard({required this.request, required this.ref});

  @override
  Widget build(BuildContext context) {
    final initial = request.fullNameAr.trim().isNotEmpty
        ? request.fullNameAr.trim()[0]
        : '؟';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullNameAr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.judicialRank,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        request.currentCourt,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule,
                          size: 11, color: Color(0xFF8B6914)),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('dd/MM').format(request.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B6914),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      minimumSize: const Size(0, 42),
                    ),
                    onPressed: () => _reject(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 42),
                    ),
                    onPressed: () async {
                      await ref
                          .read(adminRepositoryProvider)
                          .approve(request.userId);
                      ref.invalidate(pendingProvider);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (c) => const _RejectDialog(),
    );
    if (result != null) {
      await ref.read(adminRepositoryProvider).reject(request.userId, result);
      ref.invalidate(pendingProvider);
    }
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('سبب الرفض'),
      content: TextField(
        controller: _reason,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'اكتب السبب (اختياري)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _reason.text.trim()),
          child: const Text('رفض', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    );
  }
}

class _BroadcastDialog extends StatefulWidget {
  const _BroadcastDialog();
  @override
  State<_BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<_BroadcastDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إشعار جماعي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'العنوان'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'النص'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            final t = _title.text.trim();
            final b = _body.text.trim();
            if (t.isEmpty || b.isEmpty) return;
            Navigator.pop(context, (title: t, body: b));
          },
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}
