import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:iqra/pages/azanPage.dart';
import 'package:iqra/pages/azkarPage.dart';
import 'package:iqra/pages/homePage.dart';
import 'package:iqra/pages/moshafPage.dart';
import 'package:iqra/pages/namesPage.dart';
import 'package:iqra/pages/radioPage.dart';
import 'package:iqra/pages/startupPage.dart';
import 'package:iqra/pages/surahPage.dart';
import 'package:iqra/services/apiService.dart';
import 'package:iqra/pages/adhanAlertPage.dart';
import 'package:iqra/services/adhan_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.iqra.audio',
      androidNotificationChannelName: 'تلاوة القرآن الكريم',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_launcher',
    );
  } catch (e) {
    debugPrint('JustAudioBackground init failed: $e');
  }

  try {
    await AdhanService.instance.init();
    AdhanService.instance.onTap = (p) =>
        navigatorKey.currentState?.pushNamed('/adhan', arguments: p);
    AdhanService.instance.requestPermissions(); // بدون await
  } catch (e) {
    debugPrint('AdhanService init failed: $e');
  }

  bool ready = false;
  try {
    ready = await ApiService.isQuranDownloaded() &&
        await ApiService.isAzkarDownloaded();
  } catch (_) {}

  final route = AdhanService.instance.launchedByAdhan
      ? '/adhan'
      : (ready ? '/home' : '/startup');
  runApp(MyApp(initialRoute: route));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اقرأ',
      initialRoute: initialRoute,
      routes: {
        '/startup': (context) => Startuppage(),
        '/home': (context) => Homepage(),
        '/moshaf': (context) => Moshafpage(),
        '/surah': (context) => Surahpage(),
        '/azan': (context) => Azanpage(),
        '/radio': (context) => Radiopage(),
        '/names': (context) => Namespage(),
        '/azkar': (context) => Azkarpage(),
        '/adhan': (context) => AdhanAlertpage(),
      },
    );
  }
}