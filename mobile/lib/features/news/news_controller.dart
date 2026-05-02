import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news.dart';
import '../../data/providers/providers.dart';

class NewsListState {
  final List<NewsItem> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const NewsListState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 1,
    this.error,
  });

  NewsListState copyWith({
    List<NewsItem>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
  }) {
    return NewsListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NewsListController extends StateNotifier<NewsListState> {
  final Ref ref;
  NewsListController(this.ref) : super(const NewsListState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true, page: 1);
    try {
      final items = await ref.read(newsRepositoryProvider).list(page: 1);
      state = state.copyWith(
        items: items,
        page: 1,
        hasMore: items.length >= 20,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'تعذر تحميل الأخبار',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.page + 1;
      final items = await ref.read(newsRepositoryProvider).list(page: next);
      state = state.copyWith(
        items: [...state.items, ...items],
        page: next,
        hasMore: items.length >= 20,
        loadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}

final newsListControllerProvider =
    StateNotifierProvider.autoDispose<NewsListController, NewsListState>(
        (ref) => NewsListController(ref));
