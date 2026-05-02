import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/contract.dart';
import '../../../data/providers/providers.dart';
import '../../auth/auth_controller.dart';
import 'pdf_viewer_screen.dart';

final contractsListProvider =
    FutureProvider.autoDispose<List<Contract>>((ref) {
  return ref.read(contractsRepositoryProvider).list();
});

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contractsListProvider);
    final isAdmin = ref.watch(authControllerProvider).user?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التعاقدات'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'رفع تعاقد',
              onPressed: () => context.push('/contracts/new'),
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
              const Text('تعذر تحميل التعاقدات'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                onPressed: () => ref.refresh(contractsListProvider),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) return _emptyState(context, ref, isAdmin);

          // Group contracts by category for cleaner navigation
          final grouped = <String, List<Contract>>{};
          for (final c in items) {
            final key = (c.category != null && c.category!.isNotEmpty)
                ? c.category!
                : 'بدون فئة';
            grouped.putIfAbsent(key, () => []).add(c);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(contractsListProvider),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _StatsHeader(total: items.length, categories: grouped.length),
                const SizedBox(height: 16),
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
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
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.value.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ContractCard(
                          contract: c,
                          isAdmin: isAdmin,
                          onOpen: () => _open(context, c),
                          onDelete: () => _confirmDelete(context, ref, c),
                        ),
                      )),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, Contract contract) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          fileUrl: contract.fileUrl,
          title: contract.title,
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref, bool isAdmin) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(contractsListProvider),
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
                        Icons.folder_outlined,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'مفيش تعاقدات حاليًا',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAdmin
                          ? 'اضغط زرار + لرفع تعاقد جديد'
                          : 'هتظهر هنا التعاقدات لما الإدارة ترفعها',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Contract c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعاقد'),
        content: Text('متأكد من حذف "${c.title}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(contractsRepositoryProvider).remove(c.id);
      ref.invalidate(contractsListProvider);
    }
  }
}

// --- Header summary ---

class _StatsHeader extends StatelessWidget {
  final int total;
  final int categories;
  const _StatsHeader({required this.total, required this.categories});

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total تعاقد',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'مقسّمة على $categories ${categories == 1 ? "فئة" : "فئات"}',
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
    );
  }
}

// --- Contract Card ---

class _ContractCard extends StatelessWidget {
  final Contract contract;
  final bool isAdmin;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ContractCard({
    required this.contract,
    required this.isAdmin,
    required this.onOpen,
    required this.onDelete,
  });

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PDF icon block
              Container(
                width: 52,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contract.description != null &&
                        contract.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        contract.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('dd MMM yyyy', 'ar').format(contract.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (contract.fileSize != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.attach_file,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            _formatSize(contract.fileSize),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing action
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 4, top: 18),
                  child: Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
