import 'package:hijri/hijri_calendar.dart';

String toArabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

class HijriDateService {
  static String getToday() {
    HijriCalendar.setLocal('ar');

    final hijri = HijriCalendar.now();

    return '${toArabicDigits(hijri.hDay)} '
        '${hijri.getLongMonthName()} '
        '${toArabicDigits(hijri.hYear)} هـ';
  }
}