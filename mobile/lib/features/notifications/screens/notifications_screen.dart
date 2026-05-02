import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/notification.dart';
import '../../../data/providers/providers.dart';

final notificationsListProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.read(notificationsRepositoryProvider).list();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
              ref.invalidate(notificationsListProvider);
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذر تحميل الإشعارات')),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(notificationsListProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text('مفيش إشعارات',
                              style: TextStyle(color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('اسحب لأسفل للتحديث',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(notificationsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = items[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          (n.isRead ? AppColors.textSecondary : AppColors.primary).withValues(alpha: 0.1),
                      child: Icon(
                        Icons.notifications,
                        color: n.isRead ? AppColors.textSecondary : AppColors.primary,
                      ),
                    ),
                    title: Text(n.title,
                        style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy - hh:mm a', 'ar').format(n.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    onTap: () async {
                      if (!n.isRead) {
                        await ref.read(notificationsRepositoryProvider).markRead(n.id);
                        ref.invalidate(notificationsListProvider);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
