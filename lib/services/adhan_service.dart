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
    Muezzin('mishary', 'مشاري العفاسي', 'adhan_mishary'),
  ];

  static const _daysAhead = 20;
  static const _testId = 999999;

  final _plugin = FlutterLocalNotificationsPlugin();
  SharedPreferences? _prefs;
  Coordinates? _last;

  int selected = 0;
  bool enabled = true;

  void Function(String? payload)? onTap;
  bool launchedByAdhan = false;
  String? launchPayload;

  Muezzin get current => muezzins[selected];

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    _prefs = await SharedPreferences.getInstance();
    selected = (_prefs!.getInt('muezzin') ?? 0).clamp(0, muezzins.length - 1);
    enabled = _prefs!.getBool('adhan_enabled') ?? true;

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_iqra'),
      ),
      onDidReceiveNotificationResponse: (r) => onTap?.call(r.payload),
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      launchedByAdhan = true;
      launchPayload = launch!.notificationResponse?.payload;
    }
  }

  Future<void> requestPermissions() async {
    final a = _android;
    await a?.requestNotificationsPermission();
    await a?.requestExactAlarmsPermission();
    await a?.requestFullScreenIntentPermission();
  }

  NotificationDetails _details() {
    final m = current;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'adhan_${m.id}',
        'الأذان - ${m.name}',
        channelDescription: 'تنبيه الأذان',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(m.raw),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        autoCancel: false,
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
    final details = _details();

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
          details,
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
    payload: 'أذان|$_testId',
  );

  Future<void> stop(int id) => _plugin.cancel(id);
}