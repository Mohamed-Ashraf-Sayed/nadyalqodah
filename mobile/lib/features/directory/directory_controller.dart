import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/member.dart';
import '../../data/providers/providers.dart';
import '../../data/repositories/members_repository.dart';

class DirectoryFilters {
  final String? q;
  final String? governorate;
  final String? judicialRank;
  final String? specialization;

  const DirectoryFilters({this.q, this.governorate, this.judicialRank, this.specialization});

  DirectoryFilters copyWith({
    String? q,
    String? governorate,
    String? judicialRank,
    String? specialization,
    bool clearQ = false,
  }) {
    return DirectoryFilters(
      q: clearQ ? null : (q ?? this.q),
      governorate: governorate ?? this.governorate,
      judicialRank: judicialRank ?? this.judicialRank,
      specialization: specialization ?? this.specialization,
    );
  }
}

class DirectoryState {
  final List<Member> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int page;
  final String? error;
  final DirectoryFilters filters;
  final MembersFilters? meta;

  const DirectoryState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 1,
    this.error,
    this.filters = const DirectoryFilters(),
    this.meta,
  });

  DirectoryState copyWith({
    List<Member>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? error,
    DirectoryFilters? filters,
    MembersFilters? meta,
    bool clearError = false,
  }) {
    return DirectoryState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      meta: meta ?? this.meta,
    );
  }
}

class DirectoryController extends StateNotifier<DirectoryState> {
  final Ref ref;
  DirectoryController(this.ref) : super(const DirectoryState()) {
    refresh();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final m = await ref.read(membersRepositoryProvider).filters();
      state = state.copyWith(meta: m);
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true, page: 1);
    try {
      final res = await ref.read(membersRepositoryProvider).list(
            page: 1,
            q: state.filters.q,
            governorate: state.filters.governorate,
            judicialRank: state.filters.judicialRank,
            specialization: state.filters.specialization,
          );
      state = state.copyWith(
        items: res.items,
        hasMore: res.hasMore,
        loading: false,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: 'حصل خطأ في تحميل الدليل');
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.page + 1;
      final res = await ref.read(membersRepositoryProvider).list(
            page: next,
            q: state.filters.q,
            governorate: state.filters.governorate,
            judicialRank: state.filters.judicialRank,
            specialization: state.filters.specialization,
          );
      state = state.copyWith(
        items: [...state.items, ...res.items],
        hasMore: res.hasMore,
        page: next,
        loadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }

  void setQuery(String q) {
    state = state.copyWith(filters: state.filters.copyWith(q: q.isEmpty ? null : q, clearQ: q.isEmpty));
    refresh();
  }

  void setFilters(DirectoryFilters f) {
    state = state.copyWith(filters: f);
    refresh();
  }

  void clearFilters() {
    state = state.copyWith(filters: const DirectoryFilters());
    refresh();
  }
}

final directoryControllerProvider =
    StateNotifierProvider<DirectoryController, DirectoryState>((ref) => DirectoryController(ref));
