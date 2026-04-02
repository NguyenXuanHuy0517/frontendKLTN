class PagedResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalItems;
  final bool hasNext;

  const PagedResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.hasNext,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return PagedResult<T>(
      items: rawItems
          .map(
            (item) => itemFromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList(),
      page: _toInt(json['page']),
      size: _toInt(json['size']),
      totalItems: _toInt(json['totalItems']),
      hasNext: json['hasNext'] == true,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
