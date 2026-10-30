import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// TS Minicab is a London operator: every time in the app — pickups,
/// bookings, audit entries — is shown in London time (GMT/BST) whatever the
/// device's own timezone, so the office, drivers and TfL all read the same
/// clock. Call [initLondonTime] once at startup.
late final tz.Location _london;

void initLondonTime() {
  tzdata.initializeTimeZones();
  _london = tz.getLocation('Europe/London');
}

DateTime toLondon(DateTime dt) => tz.TZDateTime.from(dt, _london);

final _currencyFormat = NumberFormat.currency(locale: 'en_GB', symbol: '£');
final _dateTimeFormat = DateFormat('EEE d MMM, HH:mm');
final _dateFormat = DateFormat('d MMM yyyy');
final _auditFormat = DateFormat('dd/MM/yyyy HH:mm:ss.SSS');

String formatCurrency(num amount) => _currencyFormat.format(amount);

String formatDateTime(DateTime dt) => _dateTimeFormat.format(toLondon(dt));

String formatDate(DateTime dt) => _dateFormat.format(toLondon(dt));

/// Millisecond precision, for booking history / audit entries.
String formatAuditTime(DateTime dt) => _auditFormat.format(toLondon(dt));

/// "2026-10-30" — for date-only API fields (expiry dates, date of birth).
String dateOnly(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

/// Operating centre number shown to drivers instead of the passenger's own
/// (TfL: drivers and passengers don't contact each other directly).
const operatorPhoneDisplay = '+44 20 3679 2664';
const operatorPhoneHref = 'tel:+442036792664';
