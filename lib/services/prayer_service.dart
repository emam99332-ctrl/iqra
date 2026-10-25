import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' show Locale;
import 'package:geocoding/geocoding.dart' show Geocoding;
import 'package:iqra/services/adhan_service.dart';

String arabicDigits(String s) => s.replaceAllMapped(
  RegExp(r'\d'),
      (m) => String.fromCharCode(0x0660 + int.parse(m[0]!)),
);

String formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  final suffix = t.hour < 12 ? 'ص' : 'م';
  return '${arabicDigits('$h:$m')} $suffix';
}

String formatHM(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return arabicDigits(h > 0 ? '${h}س ${m}د' : '${m}د');
}

String formatDuration(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return arabicDigits('$h:$m:$s');
}

class PrayerService extends ChangeNotifier {
  PrayerService._();
  static final PrayerService instance = PrayerService._();

  static final _defaultCoordinates = Coordinates(30.0444, 31.2357);

  Coordinates? _coordinates;
  DateTime? _tomorrowFajr;
  DateTime? _yesterdayIsha;
  bool _started = false;
  int _day = -1;

  PrayerTimes? today;
  String? note;
  String placeName = 'انتظر من فضلك';
  bool refreshing = false;
  DateTime now = DateTime.now();

  Future<void> init() async {
    if (_started) return;
    _started = true;
    await _locate();
    _recompute();
    Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<String?> _placeName(double lat, double lng) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(
        lat,
        lng,
        locale: const Locale('ar', 'EG'),
      );
      if (marks.isEmpty) return null;
      final p = marks.first;
      final city = (p.locality?.isNotEmpty ?? false)
          ? p.locality
          : p.subAdministrativeArea;
      final parts = <String>[];
      for (final s in [city, p.administrativeArea]) {
        if (s != null && s.isNotEmpty && !parts.contains(s)) parts.add(s);
      }
      return parts.isEmpty ? null : parts.join('، ');
    } catch (_) {
      return null;
    }
  }
  Future<void> _locate() async {
    _coordinates = _defaultCoordinates;
    placeName = 'القاهرة';
    note = 'تعذر تحديد موقعك، الأوقات محسوبة للقاهرة';
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final p = await Geolocator.getCurrentPosition()
              .timeout(const Duration(seconds: 15));
          _coordinates = Coordinates(p.latitude, p.longitude);
          note = null;
          placeName =
              await _placeName(p.latitude, p.longitude) ?? 'موقعك الحالي';
        }
      }
    } catch (_) {}
  }

  Future<void> refresh() async {
    if (refreshing) return;
    refreshing = true;
    notifyListeners();
    await _locate();
    refreshing = false;
    _recompute();
  }

  void _recompute() {
    final c = _coordinates;
    if (c == null) return;
    final params = CalculationMethod.egyptian.getParameters();
    final current = DateTime.now();
    today = PrayerTimes.today(c, params);
    _tomorrowFajr = PrayerTimes(
      c,
      DateComponents.from(current.add(const Duration(days: 1))),
      params,
    ).fajr;
    _yesterdayIsha = PrayerTimes(
      c,
      DateComponents.from(current.subtract(const Duration(days: 1))),
      params,
    ).isha;
    _day = current.day;
    now = current;
    AdhanService.instance.schedule(c);
    notifyListeners();
  }

  void _tick() {
    final current = DateTime.now();
    if (today != null && current.day != _day) {
      _recompute();
      return;
    }
    now = current;
    notifyListeners();
  }

  List<MapEntry<String, DateTime>> get rows {
    final t = today!;
    return [
      MapEntry('الفجر', t.fajr),
      MapEntry('الشروق', t.sunrise),
      MapEntry('الظهر', t.dhuhr),
      MapEntry('العصر', t.asr),
      MapEntry('المغرب', t.maghrib),
      MapEntry('العشاء', t.isha),
    ];
  }

  MapEntry<String, DateTime>? get next {
    final t = today;
    if (t == null) return null;
    final prayers = [
      MapEntry('الفجر', t.fajr),
      MapEntry('الظهر', t.dhuhr),
      MapEntry('العصر', t.asr),
      MapEntry('المغرب', t.maghrib),
      MapEntry('العشاء', t.isha),
    ];
    for (final p in prayers) {
      if (p.value.isAfter(now)) return p;
    }
    return MapEntry('الفجر', _tomorrowFajr!);
  }

  Duration get remaining {
    final n = next;
    if (n == null) return Duration.zero;
    final d = n.value.difference(now);
    return d.isNegative ? Duration.zero : d;
  }

  MapEntry<String, DateTime>? get previous {
    final t = today;
    if (t == null) return null;
    final prayers = [
      MapEntry('الفجر', t.fajr),
      MapEntry('الظهر', t.dhuhr),
      MapEntry('العصر', t.asr),
      MapEntry('المغرب', t.maghrib),
      MapEntry('العشاء', t.isha),
    ];
    MapEntry<String, DateTime>? last;
    for (final p in prayers) {
      if (!p.value.isAfter(now)) last = p;
    }
    return last ?? MapEntry('العشاء', _yesterdayIsha!);
  }
}