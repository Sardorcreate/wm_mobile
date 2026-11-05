// Display formatting shared by the stock screens. Same output as the web
// client's formatDate / formatPrice in shared.js.

final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

/// `2026-02-01` -> `01.02.2026`. Returns `-` for anything else.
///
/// Reads the text directly instead of going through [DateTime]: these are
/// calendar dates, so no timezone may ever shift them by a day.
String formatDate(String? iso) {
  final match = _isoDate.firstMatch(iso ?? '');
  if (match == null) return '-';
  return '${match[3]}.${match[2]}.${match[1]}';
}

/// [date] as the `yyyy-MM-dd` text the API expects.
String isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Parses a `yyyy-MM-dd` value back into a date, or null.
DateTime? parseIsoDate(String? iso) {
  final match = _isoDate.firstMatch(iso ?? '');
  if (match == null) return null;
  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
}

/// `1234567.5` -> `1 234 567,50`. Returns `-` when there is no value.
String formatPrice(num? value) {
  if (value == null) return '-';
  return _grouped(value.toStringAsFixed(2));
}

/// Like [formatPrice] but without trailing zeros: `1500000` -> `1 500 000`.
String formatSum(num value) {
  var fixed = value.toStringAsFixed(2);
  if (fixed.contains('.')) {
    fixed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return _grouped(fixed);
}

String _grouped(String fixed) {
  final negative = fixed.startsWith('-');
  final unsigned = negative ? fixed.substring(1) : fixed;
  final parts = unsigned.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+$)'),
    (_) => ' ',
  );
  final fraction = parts.length > 1 ? ',${parts[1]}' : '';
  return '${negative ? '-' : ''}$whole$fraction';
}

/// Upper-cases the first letter. Returns `-` when empty.
String capitalize(String? text) {
  if (text == null || text.isEmpty) return '-';
  return text[0].toUpperCase() + text.substring(1);
}
