import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iqra/models/ayah.dart';
import 'package:iqra/models/surah.dart';
import 'package:iqra/models/azkar.dart';
import 'package:iqra/services/offline_store.dart';
class ApiService {
  static const _base = 'https://api.alquran.cloud/v1';
  static List<Surah>? _surahs;
  static List<dynamic>? _quranRaw;
  static bool _quranTried = false;

  static Future<void> _loadQuran() async {
    if (_quranTried) return;
    _quranTried = true;
    try {
      final data = await OfflineStore.readJson('quran.json');
      if (data is List && data.length == 114) _quranRaw = data;
    } catch (_) {}
  }

  static Future<bool> isQuranDownloaded() async {
    await _loadQuran();
    return _quranRaw != null;
  }

  static Future<void> downloadQuran() async {
    final res = await http
        .get(Uri.parse('$_base/quran/quran-uthmani'))
        .timeout(const Duration(seconds: 90));
    if (res.statusCode != 200) {
      throw Exception('خطأ في الاتصال: ${res.statusCode}');
    }
    final surahs =
    jsonDecode(utf8.decode(res.bodyBytes))['data']['surahs'] as List;
    if (surahs.length != 114) throw Exception('بيانات المصحف غير مكتملة');
    final first = (surahs.first['ayahs'] as List).first;
    if (first['text'] is! String ||
        first['numberInSurah'] is! int ||
        first['number'] is! int) {
      throw Exception('شكل البيانات غير متوقع');
    }
    await OfflineStore.writeJson('quran.json', surahs);
    _quranRaw = surahs;
    _quranTried = true;
    _surahs = null;
    _surahCache.clear();
  }

  static Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$_base/$path'));
    if (res.statusCode != 200) {
      throw Exception('خطأ في الاتصال: ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes))['data'];
  }

  static Future<List<Surah>> getSurahs() async {
    if (_surahs != null) return _surahs!;
    await _loadQuran();
    final raw = _quranRaw;
    if (raw != null) {
      return _surahs = [
        for (final s in raw)
          Surah(
            number: s['number'],
            name: s['name'],
            englishName: '${s['englishName'] ?? ''}',
            numberOfAyahs: (s['ayahs'] as List).length,
            isMakkia: s['revelationType'] == 'Meccan',
          ),
      ];
    }
    final data = await _get('surah') as List;
    return _surahs = data.map((e) => Surah.fromJson(e)).toList();
  }

  static Map<String, dynamic>? _azkarFile;
  static bool _azkarTried = false;

  static Future<void> _loadAzkar() async {
    if (_azkarTried) return;
    _azkarTried = true;
    try {
      final data = await OfflineStore.readJson('azkar.json');
      if (data is Map<String, dynamic>) _azkarFile = data;
    } catch (_) {}
  }

  static Future<bool> isAzkarDownloaded() async {
    await _loadAzkar();
    return _azkarFile != null;
  }

  static Future<dynamic> _getIslamicRetry(String path) async {
    Object? error;
    for (var i = 0; i < 3; i++) {
      try {
        return await _getIslamic(path);
      } catch (e) {
        error = e;
        await Future.delayed(Duration(seconds: 1 + i));
      }
    }
    throw error!;
  }

  static Future<void> downloadAzkar(
      void Function(int done, int total) onProgress,) async {
    final cats = (await _getIslamicRetry('dhikr'))['categories'] as List;
    final duas = <String, dynamic>{};
    for (var i = 0; i < cats.length; i++) {
      final number = '${cats[i]['number']}';
      final data = await _getIslamicRetry('dhikr/$number');
      duas[number] = [
        for (final d in data['duas'] as List)
          {
            'number': d['number'],
            'ar': {'text': d['ar']['text']},
            if (d['repeatCount'] != null) 'repeatCount': d['repeatCount'],
          },
      ];
      onProgress(i + 1, cats.length);
    }
    final Map<String, dynamic> file = {'categories': cats, 'duas': duas};
    await OfflineStore.writeJson('azkar.json', file);
    _azkarFile = file;
    _azkarTried = true;
    _azkarCategories = null;
    _azkarCache.clear();
  }

  static final Map<int, List<Ayah>> _surahCache = {};

  static Future<List<Ayah>> getSurahAyahs(int surah) async {
    if (_surahCache.containsKey(surah)) return _surahCache[surah]!;
    await _loadQuran();
    final raw = _quranRaw;
    if (raw != null) {
      final s = raw.firstWhere((s) => s['number'] == surah);
      final name = s['name'] as String;
      return _surahCache[surah] = [
        for (final a in s['ayahs'] as List) Ayah.fromParts(a, surah, name),
      ];
    }
    final data = await _get('surah/$surah/quran-uthmani');
    final name = data['name'] as String;
    return _surahCache[surah] = [
      for (final a in data['ayahs'] as List) Ayah.fromParts(a, surah, name),
    ];
  }

  static const _islamic = 'https://api.islamic.app/v1';
  static List<AzkarCategory>? _azkarCategories;
  static final Map<String, List<Zikr>> _azkarCache = {};

  static Future<dynamic> _getIslamic(String path) async {
    final res = await http.get(Uri.parse('$_islamic/$path'));
    if (res.statusCode != 200) {
      throw Exception('خطأ في الاتصال: ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes))['data'];
  }

  static Future<List<AzkarCategory>> getAzkarCategories() async {
    if (_azkarCategories != null) return _azkarCategories!;
    await _loadAzkar();
    final file = _azkarFile;
    final List raw = file != null
        ? file['categories'] as List
        : (await _getIslamic('dhikr'))['categories'] as List;
    return _azkarCategories =
        raw.map((e) => AzkarCategory.fromJson(e)).toList();
  }

  static Future<List<Zikr>> getAzkar(String category) async {
    if (_azkarCache.containsKey(category)) return _azkarCache[category]!;
    await _loadAzkar();
    final offline = _azkarFile?['duas']?[category];
    final List raw = offline is List
        ? offline
        : (await _getIslamic('dhikr/$category'))['duas'] as List;
    return _azkarCache[category] = raw.map((e) => Zikr.fromJson(e)).toList();
  }
}
