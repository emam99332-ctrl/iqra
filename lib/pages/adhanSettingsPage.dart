import 'package:flutter/material.dart';
import 'package:iqra/services/adhan_service.dart';
import 'package:iqra/styles/style.dart';

class AdhanSettingspage extends StatelessWidget {
  const AdhanSettingspage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AdhanService.instance;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),  
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('إعدادات الأذان', style: titleStyle()),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
        elevation: 0,  
      ),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => ListView(
          children: [
            Directionality(
                textDirection: TextDirection.rtl,
                child: SwitchListTile(
              activeThumbColor: emerald,
              title: const Text('تفعيل الأذان',
                  style: TextStyle(
                      fontFamily: 'ar',
                      fontWeight: FontWeight.bold,
                      color: emerald)),
              value: s.enabled,
              onChanged: s.setEnabled,
            )),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('صوت الأذان',textAlign: TextAlign.right,
                  style: TextStyle(
                      fontFamily: 'ar',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: gold)),
            ),
            for (var i = 0; i < AdhanService.muezzins.length; i++)
              Directionality(textDirection: TextDirection.rtl,
                child: ListTile(
                title: Text(AdhanService.muezzins[i].name,
                    style: const TextStyle(
                        fontFamily: 'ar',
                        fontWeight: FontWeight.bold,
                        color: emerald)),
                trailing: s.selected == i
                    ? const Icon(Icons.check_circle, color: emerald)
                    : const Icon(Icons.circle_outlined, color: gold),
                onTap: () => s.setMuezzin(i),
              )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: emerald),
                icon: const Icon(Icons.volume_up, color: cream),
                label: const Text('تجربة الصوت',
                    style: TextStyle(fontFamily: 'ar', color: cream)),
                onPressed: s.test,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerAdhanSettingspage extends StatelessWidget {
  final int prayerIndex;
  const PrayerAdhanSettingspage({super.key, required this.prayerIndex});

  @override
  Widget build(BuildContext context) {
    final s = AdhanService.instance;
    final name = AdhanService.prayerNames[prayerIndex];
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text('أذان $name', style: titleStyle()),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final custom = s.overrideOf(prayerIndex);
          return Directionality(
              textDirection: TextDirection.rtl,
              child:  ListView(
            children: [
              ListTile(
                title: Text(
                  'الافتراضي (${AdhanService.muezzins[s.selected].name})',
                  style: const TextStyle(
                      fontFamily: 'ar',
                      fontWeight: FontWeight.bold,
                      color: emerald),
                ),
                trailing: Icon(
                  custom == null
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: custom == null ? emerald : gold,
                ),
                onTap: () => s.setPrayerMuezzin(prayerIndex, null),
              ),
              const Divider(),
              for (var i = 0; i < AdhanService.muezzins.length; i++)
                ListTile(
                  title: Text(
                    AdhanService.muezzins[i].name,
                    style: const TextStyle(
                        fontFamily: 'ar',
                        fontWeight: FontWeight.bold,
                        color: emerald),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline,
                            color: gold),
                        onPressed: () =>
                            s.preview(AdhanService.muezzins[i]),
                      ),
                      Icon(
                        custom == i
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: custom == i ? emerald : gold,
                      ),
                    ],
                  ),
                  onTap: () => s.setPrayerMuezzin(prayerIndex, i),
                ),
            ],
          ));
        },
      ),
    );
  }
}