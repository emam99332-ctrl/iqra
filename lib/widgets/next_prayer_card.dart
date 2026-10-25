import 'package:flutter/material.dart';
import 'package:iqra/services/prayer_service.dart';
import 'package:iqra/styles/style.dart';

class NextPrayerCard extends StatelessWidget {
  final VoidCallback? onTap;
  const NextPrayerCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final service = PrayerService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final next = service.next;
        return Card(color: emerald,
          child: InkWell(
            onTap: onTap,
            child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [emerald.withValues(alpha: .7), gold.withValues(alpha: .7)]), borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(20),
              child: next == null
                  ? const Center(child: CircularProgressIndicator(color: emerald,))
                  : Column(
                children: [
                  Text(
                    'الصلاة القادمة: ${next.key}',
                    style: TextStyle(fontSize: 20, color: cream, fontFamily: 'ar', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatDuration(service.remaining),
                    style: TextStyle(
                      color: cream,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ar'
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}