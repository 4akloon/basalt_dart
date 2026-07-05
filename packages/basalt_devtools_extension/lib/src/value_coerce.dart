/// Filter operators keyed by wire value, mapped to a display label.
const filterOps = <String, String>{
  'eq': '=',
  'ne': '≠',
  'lt': '<',
  'le': '≤',
  'gt': '>',
  'ge': '≥',
  'like': 'LIKE',
  'isNull': 'IS NULL',
  'isNotNull': 'IS NOT NULL',
};

bool opNeedsValue(String op) => op != 'isNull' && op != 'isNotNull';

/// Coerces text field input into a typed value for the given canonical column
/// [type] (`integer` / `real` / `boolean` / `text` / `dateTime` / `blob`).
Object? coerceValue(String type, String text, {bool emptyIsNull = false}) {
  if (emptyIsNull && text.isEmpty) return null;
  switch (type) {
    case 'integer':
      return int.tryParse(text) ?? text;
    case 'real':
      return double.tryParse(text) ?? text;
    case 'boolean':
      return text == 'true' || text == '1';
    default:
      return text;
  }
}
