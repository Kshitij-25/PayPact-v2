/// Minimal RFC 4180 CSV writer.
///
/// Fields containing a comma, quote, or newline are quoted (quotes doubled).
/// Values starting with `=`, `+`, `-`, `@` are prefixed with `'` so a title
/// like "=HYPERLINK(...)" can't run as a formula when the file is opened in a
/// spreadsheet (CSV injection) — but plain negative numbers are left alone.
String toCsv(List<List<Object?>> rows) {
  String field(Object? v) {
    var s = v?.toString() ?? '';
    final isNumber = v is num;
    if (!isNumber && s.isNotEmpty && '=+-@\t\r'.contains(s[0])) s = "'$s";
    if (s.contains(RegExp(r'[",\r\n]'))) s = '"${s.replaceAll('"', '""')}"';
    return s;
  }

  return '${rows.map((r) => r.map(field).join(',')).join('\r\n')}\r\n';
}
