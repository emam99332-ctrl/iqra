import 'package:flutter/material.dart';
import 'package:iqra/models/ayah.dart';
import 'package:iqra/models/surah.dart';
import 'package:iqra/pages/moshafPage.dart' show toArabicDigits;
import 'package:iqra/services/apiService.dart';
import 'package:iqra/services/tafsir_service.dart';
import 'package:iqra/styles/style.dart';

class Tafsirpage extends StatefulWidget {
  const Tafsirpage({super.key});

  @override
  State<Tafsirpage> createState() => _TafsirpageState();
}

class _TafsirpageState extends State<Tafsirpage> {
  late final Future<List<Surah>> _future = ApiService.getSurahs();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),  
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
        title: Text('التفسير', style: titleStyle()),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final e in TafsirService.editions)
                  ChoiceChip(
                    label: Text(e.name,
                        style: TextStyle(
                            fontFamily: 'ar',
                            fontWeight: FontWeight.bold,
                            color: TafsirService.current.id == e.id
                                ? cream
                                : emerald)),
                    selected: TafsirService.current.id == e.id,
                    selectedColor: emerald,
                    backgroundColor: cream,
                    showCheckmark: false,
                    onSelected: (_) =>
                        setState(() => TafsirService.current = e),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Surah>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: emerald));
                }
                if (snap.hasError) {
                  return Center(child: Text('${snap.error}'));
                }
                final surahs = snap.data!;
                return ListView.builder(
                  itemCount: surahs.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: Text(toArabicDigits(surahs[i].number),
                        style: const TextStyle(
                            fontFamily: 'ar',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: emerald)),
                    title: Text(surahs[i].name,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'me')),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TafsirSurahPage(surah: surahs[i])),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TafsirSurahPage extends StatefulWidget {
  final Surah surah;
  const TafsirSurahPage({super.key, required this.surah});

  @override
  State<TafsirSurahPage> createState() => _TafsirSurahPageState();
}

class _TafsirSurahPageState extends State<TafsirSurahPage> {
  late final Future<List<Object>> _future = Future.wait<Object>([
    ApiService.getSurahAyahs(widget.surah.number),
    TafsirService.surah(TafsirService.current.id, widget.surah.number),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
            '${widget.surah.name} - ${TafsirService.current.name}',
            style: const TextStyle(
                fontFamily: 'ar', fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
      ),
      body: FutureBuilder<List<Object>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: emerald));
          }
          if (snap.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('${snap.error}', textAlign: TextAlign.center),
                ));
          }
          final ayahs = snap.data![0] as List<Ayah>;
          final tafsir = snap.data![1] as Map<int, String>;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ayahs.length,
            itemBuilder: (context, i) {
              final a = ayahs[i];
              return Card(
                color: gold.withValues(alpha: 0.36),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${a.text} ﴿${toArabicDigits(a.numberInSurah)}﴾',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                            fontFamily: 'Amiri', fontSize: 22, height: 1.8),
                      ),
                      const Divider(),
                      Text(
                        tafsir[a.numberInSurah] ?? 'لا يوجد تفسير',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                            fontFamily: 'ar',
                            fontSize: 16,
                            height: 1.7,
                            color: emerald),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}