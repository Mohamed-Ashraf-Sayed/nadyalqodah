import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/suggestion.dart';
import '../../../data/providers/providers.dart';
import '../../auth/auth_controller.dart';

final mySuggestionsProvider =
    FutureProvider.autoDispose<List<Suggestion>>((ref) {
  return ref.read(suggestionsRepositoryProvider).listMine();
});

final allSuggestionsProvider =
    FutureProvider.autoDispose<List<Suggestion>>((ref) {
  return ref.read(suggestionsRepositoryProvider).listAll();
});

class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authControllerProvider).user?.isAdmin == true;
    final async = isAdmin
        ? ref.watch(allSuggestionsProvider)
        : ref.watch(mySuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'الاقتراحات والشكاوى' : 'اقتراحاتي وشكاوايا'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إرسال اقتراح أو شكوى',
            onPressed: () => context.push('/suggestions/new'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('تعذر التحميل'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                onPressed: () => ref.refresh(
                  isAdmin ? allSuggestionsProvider : mySuggestionsProvider,
                ),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) return _emptyState(context, ref, isAdmin);

          // Group by status: open first, then in_progress, then resolved/closed
          final open = items.where((s) => s.status == SuggestionStatus.open).toList();
          final inProgress =
              items.where((s) => s.status == SuggestionStatus.inProgress).toList();
          final closed = items
              .where((s) =>
                  s.status == SuggestionStatus.resolved ||
                  s.status == SuggestionStatus.closed)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                isAdmin ? allSuggestionsProvider : mySuggestionsProvider,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _StatsHeader(
                  total: items.length,
                  open: open.length,
                  inProgress: inProgress.length,
                  resolved: items
                      .where((s) => s.status == SuggestionStatus.resolved)
                      .length,
                ),
                const SizedBox(height: 16),
                if (open.isNotEmpty) ...[
                  _SectionTitle(title: 'مفتوحة', count: open.length),
                  const SizedBox(height: 8),
                  ...open.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SuggestionCard(suggestion: s, isAdmin: isAdmin),
                      )),
                  const SizedBox(height: 8),
                ],
                if (inProgress.isNotEmpty) ...[
                  _SectionTitle(title: 'قيد المراجعة', count: inProgress.length),
                  const SizedBox(height: 8),
                  ...inProgress.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SuggestionCard(suggestion: s, isAdmin: isAdmin),
                      )),
                  const SizedBox(height: 8),
                ],
                if (closed.isNotEmpty) ...[
                  _SectionTitle(title: 'منتهية', count: closed.length),
                  const SizedBox(height: 8),
                  ...closed.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SuggestionCard(suggestion: s, isAdmin: isAdmin),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref, bool isAdmin) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          isAdmin ? allSuggestionsProvider : mySuggestionsProvider,
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.feedback_outlined,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'مفيش اقتراحات أو شكاوى',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAdmin
                          ? 'لما يبعت أعضاء اقتراحات هتظهر هنا'
                          : 'اضغط زر + لإرسال اقتراح أو شكوى',
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Header summary ---

class _StatsHeader extends StatelessWidget {
  final int total;
  final int open;
  final int inProgress;
  final int resolved;
  const _StatsHeader({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.feedback_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total ${total == 1 ? "طلب" : "طلبات"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'إجمالي الاقتراحات والشكاوى',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                value: open,
                label: 'مفتوحة',
                color: AppColors.accent,
              ),
              _MiniStat(
                value: inProgress,
                label: 'قيد المراجعة',
                color: Colors.white,
              ),
              _MiniStat(
                value: resolved,
                label: 'تم الحل',
                color: const Color(0xFF6EE7B7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  const _SectionTitle({required this.title, required this.count});

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
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Suggestion Card ---

class _SuggestionCard extends ConsumerWidget {
  final Suggestion suggestion;
  final bool isAdmin;
  const _SuggestionCard({required this.suggestion, required this.isAdmin});

  bool get _isComplaint => suggestion.type == SuggestionType.complaint;

  ({Color color, String label, IconData icon}) get _statusStyle {
    switch (suggestion.status) {
      case SuggestionStatus.open:
        return (
          color: const Color(0xFF8B6914),
          label: 'مفتوح',
          icon: Icons.fiber_manual_record,
        );
      case SuggestionStatus.inProgress:
        return (
          color: AppColors.primary,
          label: 'قيد المراجعة',
          icon: Icons.hourglass_top,
        );
      case SuggestionStatus.resolved:
        return (
          color: AppColors.success,
          label: 'تم الحل',
          icon: Icons.check_circle,
        );
      case SuggestionStatus.closed:
        return (
          color: AppColors.textSecondary,
          label: 'مغلق',
          icon: Icons.lock,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = _statusStyle;
    final statusBg = suggestion.status == SuggestionStatus.open
        ? AppColors.accent.withValues(alpha: 0.18)
        : status.color.withValues(alpha: 0.12);

    return Card(
      child: InkWell(
        onTap: isAdmin ? () => _showAdminDialog(context, ref) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: type icon + title + status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isComplaint
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isComplaint
                          ? Icons.report_problem_outlined
                          : Icons.lightbulb_outline,
                      color: _isComplaint
                          ? AppColors.danger
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              suggestion.type.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: _isComplaint
                                    ? AppColors.danger
                                    : AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (suggestion.isAnonymous) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_off,
                                        size: 10,
                                        color: AppColors.textSecondary),
                                    SizedBox(width: 3),
                                    Text(
                                      'مجهول',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suggestion.subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.icon, size: 10, color: status.color),
                        const SizedBox(width: 4),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: status.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                suggestion.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              if (suggestion.hasResponse) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      right: BorderSide(
                        color: AppColors.success.withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.reply,
                              size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'رد الإدارة',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        suggestion.adminResponse!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy', 'ar').format(suggestion.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isAdmin && suggestion.userEmail != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        suggestion.userEmail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (isAdmin) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app,
                              size: 10, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text(
                            'اضغط للرد',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAdminDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String? response, SuggestionStatus status})?>(
      context: context,
      builder: (ctx) => _AdminResponseDialog(suggestion: suggestion),
    );
    if (result == null) return;
    await ref.read(suggestionsRepositoryProvider).respond(
          id: suggestion.id,
          response: result.response,
          status: result.status,
        );
    ref.invalidate(allSuggestionsProvider);
  }
}

class _AdminResponseDialog extends StatefulWidget {
  final Suggestion suggestion;
  const _AdminResponseDialog({required this.suggestion});

  @override
  State<_AdminResponseDialog> createState() => _AdminResponseDialogState();
}

class _AdminResponseDialogState extends State<_AdminResponseDialog> {
  late final TextEditingController _responseCtrl;
  late SuggestionStatus _status;

  @override
  void initState() {
    super.initState();
    _responseCtrl =
        TextEditingController(text: widget.suggestion.adminResponse ?? '');
    _status = widget.suggestion.status;
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الرد على الطلب'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الحالة', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SuggestionStatus.values.map((s) {
                final selected = s == _status;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _status = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _responseCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'الرد (اختياري)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _responseCtrl.text.trim();
            Navigator.pop(
              context,
              (response: text.isEmpty ? null : text, status: _status),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
