import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final DateFormat _date = DateFormat.yMMMd();

/// Formats a monetary amount, e.g. `$1,999.00`.
String formatMoney(num value) => _money.format(value);

/// Formats a date, e.g. `Jul 5, 2026`.
String formatDate(DateTime date) => _date.format(date);
