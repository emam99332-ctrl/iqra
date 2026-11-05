import 'package:flutter/material.dart';
import 'package:iqra/styles/style.dart';
import 'package:iqra/services/last_read.dart';
import 'package:iqra/pages/moshafPage.dart';

class LastReadCard extends StatelessWidget {
  const LastReadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LastRead.instance,
      builder: (context, _) {
        final lr = LastRead.instance;
        if (lr.surah == null) return const SizedBox.shrink(); // أول مرة: مفيش حاجة
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Moshafpage(
                    initialSurah: lr.surah!,
                    initialPage: lr.page,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark, color: emerald),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('آخر قراءة',
                              style: TextStyle(
                                  fontFamily: 'ar',
                                  fontSize: 13,
                                  color: gold,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            lr.page == null
                                ? '${lr.surahName}'
                                : '${lr.surahName} • صفحة ${toArabicDigits(lr.page!)}',
                            style: const TextStyle(
                                fontFamily: 'ar',
                                fontSize: 17,
                                color: emerald,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: emerald),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}