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
        leading: Icon(Icons.arrow_back_ios),
        title: Text('إعدادات الأذان', style: titleStyle()),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
      ),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => ListView(
          children: [
            SwitchListTile(
              activeThumbColor: emerald,
              title: const Text('تفعيل الأذان',
                  style: TextStyle(
                      fontFamily: 'ar',
                      fontWeight: FontWeight.bold,
                      color: emerald)),
              value: s.enabled,
              onChanged: s.setEnabled,
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('صوت الأذان',
                  style: TextStyle(
                      fontFamily: 'ar',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: gold)),
            ),
            for (var i = 0; i < AdhanService.muezzins.length; i++)
              ListTile(
                title: Text(AdhanService.muezzins[i].name,
                    style: const TextStyle(
                        fontFamily: 'ar',
                        fontWeight: FontWeight.bold,
                        color: emerald)),
                trailing: s.selected == i
                    ? const Icon(Icons.check_circle, color: emerald)
                    : const Icon(Icons.circle_outlined, color: gold),
                onTap: () => s.setMuezzin(i),
              ),
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