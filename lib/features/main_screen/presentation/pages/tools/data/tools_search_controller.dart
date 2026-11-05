import 'package:flutter/widgets.dart';

import 'package:wm_mobile/core/network/api_client.dart';

import 'tools_api.dart';
import 'tools_models.dart';

enum SearchPhase { idle, loading, ready, empty, error }

/// State of the search tab: the chosen type, the applied filters and the
/// current page of results. Port of the state in the web client's exist.js.
class ToolsSearchController extends ChangeNotifier {
  ToolsSearchController(this.api);

  final ToolsApi api;
  final TextEditingController nameController = TextEditingController();

  StockType? _type;
  StockFilters _filters = StockFilters.none;
  SearchPhase _phase = SearchPhase.idle;
  StockPage _result = StockPage.empty;
  String? _error;
  int _page = 1;
  int _generation = 0;
  bool _disposed = false;

  StockType? get type => _type;
  StockFilters get filters => _filters;
  SearchPhase get phase => _phase;
  StockPage get result => _result;
  String? get error => _error;
  int get page => _page;

  /// Changes with every search. Lets the UI replay its entrance on new results.
  int get generation => _generation;

  bool get hasPrevious => _page > 1;
  bool get hasNext => _page < _result.totalPages;

  /// Range shown on the current page, counted from 1.
  int get firstShown => (_page - 1) * StockPage.pageSize + 1;
  int get lastShown => firstShown + _result.items.length - 1;

  /// Filters and the name from another type wouldn't apply to this one, so they
  /// are dropped rather than left looking active.
  Future<void> selectType(StockType type) {
    if (type == _type) return search();
    _type = type;
    _filters = StockFilters.none;
    nameController.clear();
    return search();
  }

  Future<void> applyFilters(StockFilters filters) {
    _filters = filters;
    return search();
  }

  Future<void> removeFilter(FilterKey key) =>
      applyFilters(_filters.without(key));

  Future<void> clearFilters() => applyFilters(StockFilters.none);

  Future<void> reload() => search(page: _page);

  Future<void> search({int page = 1}) async {
    final type = _type;
    if (type == null) return;

    // Only the newest request may fill the list: a slow response to an earlier
    // search must not replace what the user asked for since.
    final request = ++_generation;
    _page = page;
    _phase = SearchPhase.loading;
    _error = null;
    _notify();

    final name = type.hasName ? nameController.text.trim() : '';

    try {
      final result = await api.search(
        type,
        _filters,
        name: name.isEmpty ? null : name,
        page: page,
      );
      if (_disposed || request != _generation) return;

      // Deleting the only row of the last page leaves that page empty.
      if (result.items.isEmpty && page > 1) return search(page: page - 1);

      _result = result;
      _phase = result.items.isEmpty ? SearchPhase.empty : SearchPhase.ready;
    } on SessionExpiredException {
      // AuthGuard is already taking the user to the login page.
      if (_disposed || request != _generation) return;
      _result = StockPage.empty;
      _phase = SearchPhase.idle;
    } on ApiException catch (e) {
      if (_disposed || request != _generation) return;
      _result = StockPage.empty;
      _error = e.message;
      _phase = SearchPhase.error;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    super.dispose();
  }
}
