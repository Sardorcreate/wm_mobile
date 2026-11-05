import 'package:flutter/foundation.dart';

import 'package:wm_mobile/utils/formatters.dart';

/// What the "Nima qidiryapsiz?" choice searches. [path] is the API segment.
enum StockType {
  order('order', 'Kirim'),
  tool('tool', 'Jihozlar'),
  simp('simp', 'Tez eskiruvchilar'),
  outcome('outcome', 'Chiqim');

  const StockType(this.path, this.label);

  final String path;
  final String label;

  /// Whether the search has a free-text name box.
  bool get hasName => this == tool || this == simp;

  /// Rows are documents, opened by downloading them.
  bool get isDocument => this == order || this == outcome;

  /// Simps are grouped lots with nothing to delete. The backend has no delete
  /// endpoint for outcomes, so offering one could only ever fail.
  bool get canDelete => this == tool || this == order;

  bool get hasModelAndStatus => this == tool || this == simp;

  /// Inventory ID, price range and age only exist for individual tools.
  bool get hasToolFilters => this == tool;

  /// "Faol emas" is a tool-only status.
  List<ToolStatus> get statuses => this == tool
      ? ToolStatus.values
      : const [ToolStatus.reserve, ToolStatus.inUsage];
}

enum ToolStatus {
  inactive('INACTIVE', 'Faol emas'),
  reserve('RESERVE', 'Omborda'),
  inUsage('IN_USAGE', 'Foydalanishda');

  const ToolStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ToolStatus? fromApi(Object? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}

// ── Filters ──────────────────────────────────────────────────────────────────

enum FilterKey { createdAt, model, status, inventoryId, price, years }

/// One applied filter, as shown in a chip. The price range is a single chip.
class AppliedFilter {
  const AppliedFilter(this.key, this.label, this.text);

  final FilterKey key;
  final String label;
  final String text;
}

/// The filters the results are currently narrowed by.
@immutable
class StockFilters {
  const StockFilters({
    this.createdAt,
    this.model,
    this.status,
    this.inventoryId,
    this.minPrice,
    this.maxPrice,
    this.yearsSinceIncome,
  });

  static const StockFilters none = StockFilters();

  /// `yyyy-MM-dd`.
  final String? createdAt;
  final String? model;
  final ToolStatus? status;
  final String? inventoryId;
  final num? minPrice;
  final num? maxPrice;
  final int? yearsSinceIncome;

  List<AppliedFilter> get applied {
    final min = minPrice;
    final max = maxPrice;
    return [
      if (createdAt != null)
        AppliedFilter(FilterKey.createdAt, 'Sana', formatDate(createdAt)),
      if (model != null) AppliedFilter(FilterKey.model, 'Model', model!),
      if (status != null)
        AppliedFilter(FilterKey.status, 'Holati', status!.label),
      if (inventoryId != null)
        AppliedFilter(FilterKey.inventoryId, 'ID', inventoryId!),
      if (min != null || max != null)
        AppliedFilter(FilterKey.price, 'Narxi', switch ((min, max)) {
          (final num a, final num b) => '${formatSum(a)} – ${formatSum(b)}',
          (final num a, null) => '≥ ${formatSum(a)}',
          (_, final num b) => '≤ ${formatSum(b)}',
          _ => '',
        }),
      if (yearsSinceIncome != null)
        AppliedFilter(
          FilterKey.years,
          'Kirimdan beri',
          '$yearsSinceIncome yil',
        ),
    ];
  }

  StockFilters without(FilterKey key) => StockFilters(
    createdAt: key == FilterKey.createdAt ? null : createdAt,
    model: key == FilterKey.model ? null : model,
    status: key == FilterKey.status ? null : status,
    inventoryId: key == FilterKey.inventoryId ? null : inventoryId,
    minPrice: key == FilterKey.price ? null : minPrice,
    maxPrice: key == FilterKey.price ? null : maxPrice,
    yearsSinceIncome: key == FilterKey.years ? null : yearsSinceIncome,
  );

  /// The body for `POST /tools/{type}/{page}`. Each type has its own DTO, and
  /// the name goes by a different key for tools and simps.
  Map<String, Object?> toRequest(StockType type, String? name) {
    return switch (type) {
      StockType.tool => {
        'createdAt': createdAt,
        'tool': name,
        'inventoryId': inventoryId,
        'status': status?.apiValue,
        'model': model,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'yearsSinceIncome': yearsSinceIncome,
      },
      StockType.simp => {
        'createdAt': createdAt,
        'name': name,
        'status': status?.apiValue,
        'model': model,
      },
      StockType.order || StockType.outcome => {'createdAt': createdAt},
    };
  }
}

/// What is typed into the filter sheet. Nothing reaches the search until it
/// passes [validate] and is applied; closing the sheet any other way drops it.
class FilterDraft {
  FilterDraft({
    this.createdAt,
    this.model = '',
    this.status,
    this.inventoryId = '',
    this.minPrice = '',
    this.maxPrice = '',
    this.years = '',
  });

  factory FilterDraft.from(StockFilters filters) => FilterDraft(
    createdAt: filters.createdAt,
    model: filters.model ?? '',
    status: filters.status,
    inventoryId: filters.inventoryId ?? '',
    minPrice: filters.minPrice?.toString() ?? '',
    maxPrice: filters.maxPrice?.toString() ?? '',
    years: filters.yearsSinceIncome?.toString() ?? '',
  );

  String? createdAt;
  String model;
  ToolStatus? status;
  String inventoryId;
  String minPrice;
  String maxPrice;
  String years;

  static num? _number(String text) {
    final cleaned = text.replaceAll(' ', '').replaceAll(',', '.');
    final value = num.tryParse(cleaned);
    return value != null && value.isFinite ? value : null;
  }

  /// Returns a message for the first problem, or null.
  String? validate(StockType type) {
    if (!type.hasToolFilters) return null;

    final minText = minPrice.trim();
    final maxText = maxPrice.trim();
    final yearsText = years.trim();

    final min = _number(minText);
    final max = _number(maxText);
    if ((minText.isNotEmpty && min == null) ||
        (maxText.isNotEmpty && max == null)) {
      return "Son noto'g'ri kiritilgan";
    }
    if ((min != null && min < 0) || (max != null && max < 0)) {
      return "Narx manfiy bo'lishi mumkin emas";
    }
    if (min != null && max != null && min > max) {
      return "Eng kam narx eng ko'p narxdan katta bo'lmasligi kerak";
    }

    if (yearsText.isNotEmpty) {
      final value = int.tryParse(yearsText);
      if (value == null || value < 0) {
        return "Yillar soni 0 yoki undan katta butun son bo'lishi kerak";
      }
    }
    return null;
  }

  /// Only the fields that belong to [type] are carried over.
  StockFilters toFilters(StockType type) {
    String? text(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final named = type.hasModelAndStatus;
    final tool = type.hasToolFilters;
    return StockFilters(
      createdAt: createdAt,
      model: named ? text(model) : null,
      status: named ? status : null,
      inventoryId: tool ? text(inventoryId) : null,
      minPrice: tool ? _number(minPrice) : null,
      maxPrice: tool ? _number(maxPrice) : null,
      yearsSinceIncome: tool ? int.tryParse(years.trim()) : null,
    );
  }
}

// ── Results ──────────────────────────────────────────────────────────────────

num? _asNum(Object? value) =>
    value is num ? value : num.tryParse(value?.toString() ?? '');

int _asInt(Object? value) => _asNum(value)?.toInt() ?? 0;

String? _asText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

/// One row of a search result.
sealed class StockItem {
  const StockItem();
}

/// An individual, inventoried device.
class ToolItem extends StockItem {
  const ToolItem({
    required this.id,
    this.name,
    this.model,
    this.inventoryId,
    this.createdAt,
    this.status,
  });

  factory ToolItem.fromJson(Map<String, dynamic> json) => ToolItem(
    id: _asInt(json['id']),
    name: _asText(json['tool']),
    model: _asText(json['model']),
    inventoryId: _asText(json['inventoryId']),
    createdAt: _asText(json['createdAt']),
    status: ToolStatus.fromApi(json['status']),
  );

  final int id;
  final String? name;
  final String? model;
  final String? inventoryId;
  final String? createdAt;
  final ToolStatus? status;
}

/// A grouped lot of consumables. Lots have no id: nothing can be opened or
/// deleted per row.
class SimpItem extends StockItem {
  const SimpItem({
    this.name,
    this.model,
    this.createdAt,
    this.updatedAt,
    this.price,
    this.status,
    this.count,
  });

  factory SimpItem.fromJson(Map<String, dynamic> json) => SimpItem(
    name: _asText(json['toolName']),
    model: _asText(json['model']),
    createdAt: _asText(json['createdAt']),
    updatedAt: _asText(json['updatedAt']),
    price: _asNum(json['price']),
    status: ToolStatus.fromApi(json['status']),
    count: _asNum(json['count'])?.toInt(),
  );

  final String? name;
  final String? model;
  final String? createdAt;
  final String? updatedAt;
  final num? price;
  final ToolStatus? status;
  final int? count;
}

/// An income or outcome document.
class DocumentItem extends StockItem {
  const DocumentItem({required this.id, this.createdAt});

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
    id: _asInt(json['id']),
    createdAt: _asText(json['createdAt']),
  );

  final int id;
  final String? createdAt;
}

/// One page of results. The API pages by 10.
class StockPage {
  const StockPage({
    required this.items,
    required this.totalItems,
    required this.totalPages,
  });

  factory StockPage.fromJson(StockType type, Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return StockPage(
      items: [
        for (final row in rows)
          switch (type) {
            StockType.tool => ToolItem.fromJson(row),
            StockType.simp => SimpItem.fromJson(row),
            StockType.order || StockType.outcome => DocumentItem.fromJson(row),
          },
      ],
      totalItems: _asInt(json['totalItems']),
      totalPages: _asInt(json['totalPages']),
    );
  }

  static const int pageSize = 10;
  static const StockPage empty = StockPage(
    items: [],
    totalItems: 0,
    totalPages: 0,
  );

  final List<StockItem> items;
  final int totalItems;
  final int totalPages;
}

/// The full record behind `GET /tools/tool/get_one`.
class ToolDetails {
  const ToolDetails({
    required this.id,
    this.name,
    this.owner,
    this.inventoryId,
    this.model,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.description,
    this.whereFrom,
    this.currentPlace,
    this.price,
    this.currentValue,
  });

  factory ToolDetails.fromJson(Map<String, dynamic> json) {
    // The backend's placeholder when a tool has no active outcome.
    final place = _asText(json['currentPlace']);
    return ToolDetails(
      id: _asInt(json['id']),
      name: _asText(json['tool']),
      owner: _asText(json['owner']),
      inventoryId: _asText(json['inventoryId']),
      model: _asText(json['model']),
      createdAt: _asText(json['createdAt']),
      updatedAt: _asText(json['updatedAt']),
      status: ToolStatus.fromApi(json['status']),
      description: _asText(json['description']),
      whereFrom: _asText(json['whereFrom']),
      currentPlace: place == "Chiqim joyi noma'lum" ? null : place,
      price: _asNum(json['price']),
      currentValue: _asNum(json['currentValue']),
    );
  }

  final int id;
  final String? name;
  final String? owner;
  final String? inventoryId;
  final String? model;
  final String? createdAt;
  final String? updatedAt;
  final ToolStatus? status;
  final String? description;
  final String? whereFrom;
  final String? currentPlace;
  final num? price;
  final num? currentValue;
}
