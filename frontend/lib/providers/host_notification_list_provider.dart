import 'package:flutter/material.dart';

import '../data/models/notification_model.dart';
import '../data/services/host_notification_service.dart';
import 'paged_list_state.dart';

class HostNotificationListProvider extends ChangeNotifier {
  static const _pageSize = 20;

  final _service = HostNotificationService();

  PagedListState<NotificationModel> _state =
      const PagedListState<NotificationModel>();
  final Set<int> _readingIds = <int>{};

  int? _userId;
  int _unreadCount = 0;
  bool _markingAllRead = false;
  bool? _isRead;
  String _search = '';

  PagedListState<NotificationModel> get state => _state;
  Set<int> get readingIds => _readingIds;
  int get unreadCount => _unreadCount;
  bool get markingAllRead => _markingAllRead;
  bool? get isRead => _isRead;
  String get search => _search;

  Future<void> bootstrap({required int userId}) async {
    _userId = userId;
    await refresh();
  }

  Future<void> applyFilters({bool? isRead, String? search}) async {
    final nextSearch = (search ?? _search).trim();
    if (_isRead == isRead && _search == nextSearch) {
      return;
    }
    _isRead = isRead;
    _search = nextSearch;
    await refresh();
  }

  Future<void> refresh() => _load(refresh: true);

  Future<void> loadMore() => _load(refresh: false);

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null || _markingAllRead || _unreadCount == 0) return;

    _markingAllRead = true;
    notifyListeners();
    try {
      await _service.markAllAsRead(userId);
      _state = _state.copyWith(
        items: _state.items.map((item) => item.copyWith(isRead: true)).toList(),
      );
      _unreadCount = 0;
    } finally {
      _markingAllRead = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    if (_readingIds.contains(notificationId)) return;
    final index = _state.items.indexWhere(
      (item) => item.notificationId == notificationId,
    );
    if (index == -1 || _state.items[index].isRead) return;

    _readingIds.add(notificationId);
    notifyListeners();
    try {
      await _service.markAsRead(notificationId);
      final updatedItems = [..._state.items];
      updatedItems[index] = updatedItems[index].copyWith(isRead: true);
      _state = _state.copyWith(items: updatedItems);
      if (_unreadCount > 0) {
        _unreadCount--;
      }
    } finally {
      _readingIds.remove(notificationId);
      notifyListeners();
    }
  }

  Future<void> _load({required bool refresh}) async {
    final userId = _userId;
    if (userId == null) return;

    if (refresh) {
      _state = _state.copyWith(loading: true, loadingMore: false, error: null);
      notifyListeners();
    } else {
      if (_state.loadingMore || !_state.hasNext) return;
      _state = _state.copyWith(loadingMore: true, error: null);
      notifyListeners();
    }

    try {
      final page = refresh ? 0 : _state.page + 1;
      final results = await Future.wait<dynamic>([
        _service.getNotificationsPage(
          userId: userId,
          isRead: _isRead,
          search: _search,
          page: page,
          size: _pageSize,
        ),
        if (refresh) _service.getUnreadCount(userId),
      ]);

      final notificationPage = results.first;
      final nextUnreadCount = refresh ? (results[1] as int) : _unreadCount;
      _state = _state.copyWith(
        items: refresh
            ? notificationPage.items
            : [..._state.items, ...notificationPage.items],
        page: notificationPage.page,
        totalItems: notificationPage.totalItems,
        hasNext: notificationPage.hasNext,
        loading: false,
        loadingMore: false,
        error: null,
      );
      _unreadCount = nextUnreadCount;
    } catch (_) {
      _state = _state.copyWith(
        loading: false,
        loadingMore: false,
        error: 'Khong tai duoc danh sach thong bao.',
      );
    }

    notifyListeners();
  }
}
