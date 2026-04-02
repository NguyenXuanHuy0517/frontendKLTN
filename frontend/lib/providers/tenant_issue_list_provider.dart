import 'package:flutter/material.dart';

import '../data/models/issue_model.dart';
import '../data/services/issue_service.dart';
import 'paged_list_state.dart';

class TenantIssueListProvider extends ChangeNotifier {
  static const _pageSize = 20;

  final _service = IssueService();

  PagedListState<IssueModel> _state = const PagedListState<IssueModel>();
  int? _userId;
  String _status = '';
  String _search = '';

  PagedListState<IssueModel> get state => _state;
  String get status => _status;
  String get search => _search;

  Future<void> bootstrap({required int userId}) async {
    _userId = userId;
    await refresh();
  }

  Future<void> applyFilters({String? status, String? search}) async {
    final nextStatus = status ?? _status;
    final nextSearch = (search ?? _search).trim();
    if (_status == nextStatus && _search == nextSearch) {
      return;
    }
    _status = nextStatus;
    _search = nextSearch;
    await refresh();
  }

  Future<void> refresh() => _load(refresh: true);

  Future<void> loadMore() => _load(refresh: false);

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
      final result = await _service.getTenantIssuesPage(
        userId: userId,
        status: _status,
        search: _search,
        page: refresh ? 0 : _state.page + 1,
        size: _pageSize,
      );

      _state = _state.copyWith(
        items: refresh ? result.items : [..._state.items, ...result.items],
        page: result.page,
        totalItems: result.totalItems,
        hasNext: result.hasNext,
        loading: false,
        loadingMore: false,
        error: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        loading: false,
        loadingMore: false,
        error: 'Khong tai duoc danh sach khieu nai.',
      );
    }

    notifyListeners();
  }
}
