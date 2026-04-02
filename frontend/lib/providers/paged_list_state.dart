class PagedListState<T> {
  static const Object _unset = Object();

  final List<T> items;
  final int page;
  final int totalItems;
  final bool hasNext;
  final bool loading;
  final bool loadingMore;
  final String? error;

  const PagedListState({
    this.items = const [],
    this.page = 0,
    this.totalItems = 0,
    this.hasNext = false,
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  PagedListState<T> copyWith({
    List<T>? items,
    int? page,
    int? totalItems,
    bool? hasNext,
    bool? loading,
    bool? loadingMore,
    Object? error = _unset,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      totalItems: totalItems ?? this.totalItems,
      hasNext: hasNext ?? this.hasNext,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}
