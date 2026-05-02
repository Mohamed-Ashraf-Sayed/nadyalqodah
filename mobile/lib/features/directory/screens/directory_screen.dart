import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/member_avatar.dart';
import '../directory_controller.dart';
import 'filter_sheet.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(directoryControllerProvider.notifier).loadMore();
      }
    });
    // Ensure suffix X icon updates as the user types/clears
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(directoryControllerProvider.notifier).setQuery(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directoryControllerProvider);
    final hasFilters = state.filters.governorate != null ||
        state.filters.judicialRank != null ||
        state.filters.specialization != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الأعضاء'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune),
                if (hasFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const FilterSheet(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، المحكمة، التخصص...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(directoryControllerProvider.notifier).setQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (state.loading && state.items.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null && state.items.isEmpty)
            Expanded(child: Center(child: Text(state.error!)))
          else if (state.items.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text('مفيش نتائج', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(directoryControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: state.items.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    if (i >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final m = state.items[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: MemberAvatar(photoUrl: m.photoUrl, name: m.fullNameAr),
                        title: Text(
                          m.fullNameAr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.fullNameEn != null && m.fullNameEn!.isNotEmpty)
                                Text(
                                  'الشهرة: ${m.fullNameEn}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(m.judicialRank, style: const TextStyle(color: AppColors.primary)),
                              Text(
                                m.currentCourt,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/member/${m.id}'),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
