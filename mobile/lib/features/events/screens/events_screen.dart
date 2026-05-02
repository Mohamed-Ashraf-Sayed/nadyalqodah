import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/event.dart';
import '../../../data/providers/providers.dart';
import '../../auth/auth_controller.dart';

final eventsListProvider = FutureProvider.autoDispose<List<ClubEvent>>((ref) {
  return ref.read(eventsRepositoryProvider).list();
});

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventsListProvider);
    final isAdmin = ref.watch(authControllerProvider).user?.isAdmin == true;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأحداث'),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'إضافة حدث',
                onPressed: () => context.push('/events/new'),
              ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: [
              Tab(text: 'القادمة'),
              Tab(text: 'السابقة'),
            ],
          ),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                const Text('تعذر تحميل الأحداث'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  onPressed: () => ref.refresh(eventsListProvider),
                ),
              ],
            ),
          ),
          data: (items) {
            final upcoming = items.where((e) => e.isUpcoming).toList()
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            final past = items.where((e) => e.isPast).toList()
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
            return TabBarView(
              children: [
                _UpcomingTab(items: upcoming),
                _PastTab(items: past),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- Helpers ---

IconData _categoryIcon(String? category) {
  switch (category) {
    case 'اجتماع':
      return Icons.groups_2_outlined;
    case 'تدريب':
      return Icons.school_outlined;
    case 'احتفال':
      return Icons.celebration_outlined;
    case 'رحلة':
      return Icons.flight_takeoff_outlined;
    case 'ندوة':
      return Icons.mic_outlined;
    default:
      return Icons.event_outlined;
  }
}

String _relativeLabel(DateTime startsAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(startsAt.year, startsAt.month, startsAt.day);
  final diff = eventDay.difference(today).inDays;
  if (diff == 0) return 'اليوم';
  if (diff == 1) return 'غدًا';
  if (diff > 1 && diff <= 7) return 'بعد $diff أيام';
  return '';
}

// --- Upcoming Tab ---

class _UpcomingTab extends ConsumerWidget {
  final List<ClubEvent> items;
  const _UpcomingTab({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return _EmptyEvents(isUpcoming: true, ref: ref);

    final featured = items.first;
    final rest = items.skip(1).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(eventsListProvider),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _FeaturedEventCard(event: featured),
          if (rest.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Text(
                'باقي الأحداث',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
            ...rest.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CompactEventCard(event: e),
                )),
          ],
        ],
      ),
    );
  }
}

// --- Past Tab ---

class _PastTab extends ConsumerWidget {
  final List<ClubEvent> items;
  const _PastTab({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return _EmptyEvents(isUpcoming: false, ref: ref);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(eventsListProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _CompactEventCard(event: items[i], isPast: true),
      ),
    );
  }
}

// --- Featured (next upcoming) ---

class _FeaturedEventCard extends ConsumerWidget {
  final ClubEvent event;
  const _FeaturedEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authControllerProvider).user?.isAdmin == true;
    final icon = _categoryIcon(event.category);
    final relative = _relativeLabel(event.startsAt);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative icon in background
          Positioned(
            left: -20,
            top: -10,
            child: Icon(
              icon,
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge row
                Row(
                  children: [
                    if (event.category != null && event.category!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              event.category!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (relative.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          relative,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (isAdmin)
                      InkWell(
                        onTap: () => _confirmDelete(context, ref, event),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  text: DateFormat('EEEE dd MMMM yyyy', 'ar').format(event.startsAt),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.access_time,
                  text: DateFormat('hh:mm a', 'ar').format(event.startsAt) +
                      (event.endsAt != null
                          ? ' - ${DateFormat('hh:mm a', 'ar').format(event.endsAt!)}'
                          : ''),
                ),
                if (event.location != null && event.location!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(icon: Icons.location_on_outlined, text: event.location!),
                ],
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.description!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.6,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// --- Compact card for the rest of the events ---

class _CompactEventCard extends ConsumerWidget {
  final ClubEvent event;
  final bool isPast;
  const _CompactEventCard({required this.event, this.isPast = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authControllerProvider).user?.isAdmin == true;
    final icon = _categoryIcon(event.category);
    final relative = isPast ? '' : _relativeLabel(event.startsAt);
    final accent = isPast ? AppColors.textSecondary : AppColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date column
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.15),
                    accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd', 'ar').format(event.startsAt),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM', 'ar').format(event.startsAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('hh:mm', 'ar').format(event.startsAt),
                    style: TextStyle(
                      fontSize: 9,
                      color: accent.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (event.category != null && event.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 11, color: accent),
                              const SizedBox(width: 3),
                              Text(
                                event.category!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (relative.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            relative,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF8B6914),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isAdmin && !isPast)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 20),
                onPressed: () => _confirmDelete(context, ref, event),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

// --- Empty state ---

class _EmptyEvents extends StatelessWidget {
  final bool isUpcoming;
  final WidgetRef ref;
  const _EmptyEvents({required this.isUpcoming, required this.ref});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(eventsListProvider),
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
                      child: Icon(
                        isUpcoming ? Icons.event_available : Icons.history,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isUpcoming ? 'مفيش أحداث قادمة' : 'مفيش أحداث سابقة',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isUpcoming
                          ? 'هتظهر هنا فعاليات النادي القادمة'
                          : 'الفعاليات اللي عدت هتظهر هنا',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
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

Future<void> _confirmDelete(
    BuildContext ctx, WidgetRef ref, ClubEvent event) async {
  final ok = await showDialog<bool>(
    context: ctx,
    builder: (c) => AlertDialog(
      title: const Text('حذف الحدث'),
      content: Text('متأكد من حذف "${event.title}"؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(eventsRepositoryProvider).remove(event.id);
    ref.invalidate(eventsListProvider);
  }
}
