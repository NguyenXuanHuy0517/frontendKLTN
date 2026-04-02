import 'package:flutter/material.dart';

import '../data/models/invoice_model.dart';
import '../data/services/invoice_service.dart';
import 'paged_list_state.dart';

class HostInvoiceListProvider extends ChangeNotifier {
  static const _pageSize = 20;
  static const _unset = Object();

  final _service = InvoiceService();

  PagedListState<InvoiceModel> _state = const PagedListState<InvoiceModel>();
  int? _hostId;
  String _status = '';
  String _search = '';
  int? _month;
  int? _year;

  PagedListState<InvoiceModel> get state => _state;
  String get status => _status;
  String get search => _search;
  int? get month => _month;
  int? get year => _year;

  Future<void> bootstrap({required int hostId}) async {
    _hostId = hostId;
    await refresh();
  }

  Future<void> applyFilters({
    String? status,
    String? search,
    Object? month = _unset,
    Object? year = _unset,
  }) async {
    final nextStatus = status ?? _status;
    final nextSearch = (search ?? _search).trim();
    final nextMonth = identical(month, _unset) ? _month : month as int?;
    final nextYear = identical(year, _unset) ? _year : year as int?;
    if (_status == nextStatus &&
        _search == nextSearch &&
        _month == nextMonth &&
        _year == nextYear) {
      return;
    }
    _status = nextStatus;
    _search = nextSearch;
    _month = nextMonth;
    _year = nextYear;
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
      final result = await _service.getInvoicesPage(
        hostId: hostId,
        status: _status,
        search: _search,
        month: _month,
        year: _year,
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
        error: 'Không tải được danh sách hóa đơn.',
      );
    }

    notifyListeners();
  }
}
