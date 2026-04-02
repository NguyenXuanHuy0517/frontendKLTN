import 'package:flutter/material.dart';

import '../data/models/room_model.dart';
import '../data/services/room_service.dart';
import 'paged_list_state.dart';

class HostRoomListProvider extends ChangeNotifier {
  static const _pageSize = 20;

  final _service = RoomService();

  PagedListState<RoomModel> _state = const PagedListState<RoomModel>();
  int? _hostId;
  int? _areaId;
  String _status = '';
  String _search = '';

  PagedListState<RoomModel> get state => _state;
  int? get areaId => _areaId;
  String get status => _status;
  String get search => _search;

  Future<void> bootstrap({required int hostId, int? areaId}) async {
    _hostId = hostId;
    _areaId = areaId;
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
    final hostId = _hostId;
    if (hostId == null) return;

    if (refresh) {
      _state = _state.copyWith(loading: true, loadingMore: false, error: null);
      notifyListeners();
    } else {
      if (_state.loadingMore || !_state.hasNext) return;
      _state = _state.copyWith(loadingMore: true, error: null);
      notifyListeners();
    }

    try {
      final result = await _service.getRoomsPage(
        hostId: hostId,
        areaId: _areaId,
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
        error: 'Khong tai duoc danh sach phong.',
      );
    }

    notifyListeners();
  }
}
