import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Muezzin {
  final String id;
  final String name;
  final String raw;
  const Muezzin(this.id, this.name, this.raw);
}

class AdhanService extends ChangeNotifier {
  AdhanService._();
  static final AdhanService instance = AdhanService._();

  static const muezzins = [
    Muezzin('makkah', 'أذان مكة', 'adhan_makkah'),
    Muezzin('madinah', 'أذان المدينة', 'adhan_madinah'),
    Muezzin('alaqsa', 'أذان المسجد الأقصى', 'adhan_alaqsa'),
    Muezzin('fajr', 'الشيخ عبدالباسط عبدالصمد - الفجر', 'adhan_fajr'),
    Muezzin('mishary', 'الشيخ مشاري العفاسي', 'adhan_mishary'),
    Muezzin('hosari', 'الشيخ محمود الحصرى', 'adhan_hosari'),
    Muezzin('refaat', 'الشيخ محمد رفعت', 'adhan_refaat'),
    Muezzin('said', 'الشيخ سيد النقشبندى', 'adhan_said'),
    Muezzin('zahbi', 'الشيخ عبدالله الذهبى', 'adhan_zahbi'),
  ];

  static const _daysAhead = 20;
  static const _testId = 999999;

  final _plugin = FlutterLocalNotificationsPlugin();
  SharedPreferences? _prefs;
  Coordinates? _last;

  int selected = 0;
  bool enabled = true;

  Muezzin get current => muezzins[selected];

  static const prayerNames = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  static int prayerIndex(String name) => prayerNames.indexOf(name);

  // صوت خاص بكل صلاة (null = يتبع الإعداد العام)
  final List<int?> _overrides = List.filled(5, null);
  int? overrideOf(int prayer) => _overrides[prayer];
  Muezzin muezzinFor(int prayer) => muezzins[_overrides[prayer] ?? selected];

  Future<void> setPrayerMuezzin(int prayer, int? index) async {
    _overrides[prayer] = index;
    if (index == null) {
      await _prefs?.remove('muezzin_p$prayer');
    } else {
      await _prefs?.setInt('muezzin_p$prayer', index);
    }
    notifyListeners();
    await schedule();
  }

  Future<void> preview(Muezzin m) => _plugin.show(
    _testId,
    'تجربة الأذان',
    m.name,
    _details(m),
    payload: 'أذان|$_testId',
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    _prefs = await SharedPreferences.getInstance();
    selected = (_prefs!.getInt('muezzin') ?? 0).clamp(0, muezzins.length - 1);
    enabled = _prefs!.getBool('adhan_enabled') ?? true;

    for (var i = 0; i < 5; i++) {
      final v = _prefs!.getInt('muezzin_p$i');
      _overrides[i] = (v != null && v >= 0 && v < muezzins.length) ? v : null;
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<void> requestPermissions() async {
    final a = _android;
    await a?.requestNotificationsPermission();
    await a?.requestExactAlarmsPermission();
  }

  NotificationDetails _details([Muezzin? muezzin]) {
    final m = muezzin ?? current;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'adhan_${m.id}',
        'الأذان - ${m.name}',
        channelDescription: 'تنبيه الأذان',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: false,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(m.raw),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        autoCancel: true,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  Future<void> setMuezzin(int index) async {
    selected = index;
    await _prefs?.setInt('muezzin', index);
    notifyListeners();
    await schedule();
  }

  Future<void> setEnabled(bool v) async {
    enabled = v;
    await _prefs?.setBool('adhan_enabled', v);
    notifyListeners();
    if (v) await requestPermissions();
    await schedule();
  }

  Future<void> schedule([Coordinates? coordinates]) async {
    final c = coordinates ?? _last;
    if (c == null) return;
    _last = c;

    for (final p in await _plugin.pendingNotificationRequests()) {
      await _plugin.cancel(p.id);
    }
    if (!enabled) return;

    const mode = AndroidScheduleMode.alarmClock;

    final params = CalculationMethod.egyptian.getParameters();
    final now = DateTime.now();
    final detailsCache = <String, NotificationDetails>{};
    NotificationDetails detailsFor(Muezzin m) =>
        detailsCache.putIfAbsent(m.id, () => _details(m));

    for (var d = 0; d <= _daysAhead; d++) {
      final date = now.add(Duration(days: d));
      final t = PrayerTimes(c, DateComponents.from(date), params);
      final prayers = [
        ('الفجر', t.fajr),
        ('الظهر', t.dhuhr),
        ('العصر', t.asr),
        ('المغرب', t.maghrib),
        ('العشاء', t.isha),
      ];
      final dayIndex =
          DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
              86400000;
      for (var i = 0; i < prayers.length; i++) {
        final (name, time) = prayers[i];
        if (!time.isAfter(now)) continue;
        final id = dayIndex * 10 + i;
        await _plugin.zonedSchedule(
          id,
          'حان الآن موعد أذان $name',
          'حيّ على الصلاة',
          tz.TZDateTime.from(time, tz.UTC),
          detailsFor(muezzinFor(i)),
          androidScheduleMode: mode,
          payload: '$name|$id',
        );
      }
    }
  }

  Future<void> test() => _plugin.show(
    _testId,
    'حان موعد الصلاة الان',
    current.name,
    _details(),
  );
}