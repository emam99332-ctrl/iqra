import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iqra/services/offline_store.dart';

class TafsirEdition {
  final String id;
  final String name;
  const TafsirEdition(this.id, this.name);
}

class TafsirService {
  static const editions = [
    TafsirEdition('ar.muyassar', 'التفسير الميسر'),
    TafsirEdition('ar.jalalayn', 'تفسير الجلالين'),
  ];

  static TafsirEdition current = editions[0];
  static final Map<String, Map<int, String>> _mem = {};

  static Future<Map<int, String>> surah(String edition, int surah) async {
    final key = '$edition:$surah';
    if (_mem.containsKey(key)) return _mem[key]!;

    final file = 'tafsir_${edition}_$surah.json';
    try {
      final d = await OfflineStore.readJson(file);
      if (d is Map) {
        return _mem[key] = {
          for (final e in d.entries) int.parse(e.key): e.value as String,
        };
      }
    } catch (_) {}

    final res = await http
        .get(Uri.parse('https://api.alquran.cloud/v1/surah/$surah/$edition'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('خطأ في الاتصال: ${res.statusCode}');
    }
    final ayahs = jsonDecode(utf8.decode(res.bodyBytes))['data']['ayahs'] as List;
    final map = {
      for (final a in ayahs)
        a['numberInSurah'] as int: (a['text'] as String).trim(),
    };
    await OfflineStore.writeJson(
        file, {for (final e in map.entries) '${e.key}': e.value});
    return _mem[key] = map;
  }

  static Future<String> ayah(String edition, int surah, int ayah) async {
    final m = await TafsirService.surah(edition, surah);
    return m[ayah] ?? 'لا يوجد تفسير لهذه الآية';
  }
}