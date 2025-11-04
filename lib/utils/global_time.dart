import 'package:intl/intl.dart';

class TimeUtils {
  static String nowWithZone(String zone) {
    final now = DateTime.now().toUtc();
    late Duration offset;

    switch (zone) {
      case 'WIB':
        offset = const Duration(hours: 7);
        break;
      case 'WITA':
        offset = const Duration(hours: 8);
        break;
      case 'WIT':
        offset = const Duration(hours: 9);
        break;
      case 'London':
        offset = const Duration(hours: 0);
        break;
      default:
        offset = const Duration(hours: 7);
    }

    final zonedTime = now.add(offset);
    return zonedTime.toIso8601String();
  }

  static String formatWithZone(DateTime date, String zone) {
    final nowUtc = date.toUtc();
    late Duration offset;

    switch (zone) {
      case 'WIB':
        offset = const Duration(hours: 7);
        break;
      case 'WITA':
        offset = const Duration(hours: 8);
        break;
      case 'WIT':
        offset = const Duration(hours: 9);
        break;
      case 'London':
        offset = const Duration(hours: 0);
        break;
      default:
        offset = const Duration(hours: 7);
    }

    final zoned = nowUtc.add(offset);
    return DateFormat('HH:mm').format(zoned);
  }
}
