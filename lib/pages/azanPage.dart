import 'package:flutter/material.dart';
import 'package:iqra/services/prayer_service.dart';
import 'package:iqra/widgets/next_prayer_card.dart';
import 'package:iqra/styles/style.dart';
import 'package:iqra/pages/adhanSettingsPage.dart';
import 'package:iqra/services/adhan_service.dart';

class Azanpage extends StatefulWidget {
  const Azanpage({super.key});

  @override
  State<Azanpage> createState() => _AzanpageState();
}

class _AzanpageState extends State<Azanpage> {
  final _service = PrayerService.instance;

  @override
  void initState() {
    super.initState();
    _service.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
        title: Text('مواقيت الصلاة', style: titleStyle()),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: emerald),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdhanSettingspage()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          if (_service.today == null) {
            return const Center(child: CircularProgressIndicator(color: emerald));
          }
          final next = _service.next!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const NextPrayerCard(),
              if (_service.note != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_service.note!, textAlign: TextAlign.center),
                ),
              const SizedBox(height: 8),
              for (final e in _service.rows)
                Card(
                  color: e.value == next.value
                      ? emerald.withValues(alpha: 0.15)
                      : gold,
                  child: ListTile(
                    title: Text(e.key, style: TextStyle(fontSize: 18, fontFamily: 'ar', fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (AdhanService.prayerIndex(e.key) >= 0)
                          ListenableBuilder(
                            listenable: AdhanService.instance,
                            builder: (context, _) {
                              final idx = AdhanService.prayerIndex(e.key);
                              return IconButton(
                                tooltip: 'إعدادات أذان ${e.key}',
                                icon: Icon(Icons.volume_up_rounded),
                                color: emerald,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PrayerAdhanSettingspage(
                                        prayerIndex: idx),
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 8),
                        Text(
                          formatTime(e.value),
                          style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'ar',
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}