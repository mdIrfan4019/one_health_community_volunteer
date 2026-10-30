// Utility for formatting display values and cleaning raw array strings e.g. "[...]"
// File: lib/core/utils/display_formatters.dart

/// Clean and format values (Strings, Lists, numbers) that may contain raw array brackets `[...]`,
/// quotes, or empty/null values.
///
/// Examples:
/// - `"[Public Health Department, Animal Husbandry Department]"` -> `"Public Health Department, Animal Husbandry Department"`
/// - `"[1, 2, 3]"` -> `"1, 2, 3"`
/// - `["Item 1", "Item 2"]` -> `"Item 1, Item 2"`
/// - `null`, `""`, `"[]"`, `"null"` -> `"—"`
String cleanDisplayValue(dynamic val, {String fallback = '—'}) {
  if (val == null) return fallback;
  if (val is List) {
    if (val.isEmpty) return fallback;
    final items = val
        .map((e) => cleanDisplayValue(e, fallback: ''))
        .where((s) => s.isNotEmpty && s != 'null' && s != fallback)
        .toList();
    return items.isEmpty ? fallback : items.join(', ');
  }

  var s = val.toString().trim();
  if (s.isEmpty || s == 'null' || s == '[]') return fallback;

  // Strip leading and trailing brackets if present
  if (s.startsWith('[') && s.endsWith(']')) {
    s = s.substring(1, s.length - 1).trim();
    if (s.isEmpty) return fallback;
    final parts = s
        .split(',')
        .map((p) => p.trim().replaceAll(RegExp(r"^['" + '"]|[\'"' + r']$'), '').trim())
        .where((p) => p.isNotEmpty && p != 'null' && p != '—');
    return parts.isEmpty ? fallback : parts.join(', ');
  }

  return s;
}
