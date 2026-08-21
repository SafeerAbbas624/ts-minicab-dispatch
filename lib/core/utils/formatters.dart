import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(locale: 'en_GB', symbol: '£');
final _dateTimeFormat = DateFormat('EEE d MMM, HH:mm');
final _dateFormat = DateFormat('d MMM yyyy');

String formatCurrency(num amount) => _currencyFormat.format(amount);

String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);

String formatDate(DateTime dt) => _dateFormat.format(dt);
