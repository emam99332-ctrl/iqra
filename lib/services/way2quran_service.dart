import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:iqra/services/offline_store.dart';
import 'package:iqra/services/radio_service.dart';

class W2QReciter {
  final String slug;
  final String name;
  final String? q;
  final String? asset;
  const W2QReciter(this.slug, this.name, {this.q, this.asset});

  String get thumbUrl => 'https://media.way2quran.com/imgs/thumbs/$slug.webp';
  String get imageUrl => 'https://media.way2quran.com/imgs/$slug.jpg';
  String get pageUrl => 'https://way2quran.com/ar/reciters/$slug';
}

class W2QTrack {
  final int surah;
  final String url;
  const W2QTrack(this.surah, this.url);
}

class Way2Quran {
  static const reciters = [
    W2QReciter('husary', 'محمود خليل الحصري', q: 'الحصري', asset: 'assets/reciters/0.png'),
    W2QReciter('abdulbasit', 'عبد الباسط عبد الصمد', q: 'عبد الباسط', asset: 'assets/reciters/1.png'),
    W2QReciter('minshawy', 'محمد صديق المنشاوي', q: 'المنشاوي', asset: 'assets/reciters/2.png'),
    W2QReciter('muhammad-jibreel', 'محمد جبريل', q: 'جبريل', asset: 'assets/reciters/6.png'),
    W2QReciter('muhammad-mahmoud-al-tablawi', 'محمد محمود الطبلاوي', q: 'محمد الطبلاوي',),
    W2QReciter('mustafa-ismail', 'مصطفى إسماعيل'),
    W2QReciter('mohamed-refaat', 'محمد رفعت'),
    W2QReciter('kaml-yusuf-al-bhtymy', 'كامل يوسف البهتيمي'),
    W2QReciter('alafasy', 'مشاري العفاسي', q: 'العفاسي', asset: 'assets/reciters/7.png'),
    W2QReciter('yasser', 'ياسر الدوسري', q: 'ياسر الدوسري', asset: 'assets/reciters/8.png'),
    W2QReciter('ajamy', 'أحمد العجمي', q: 'العجمي', asset: 'assets/reciters/9.png'),
    W2QReciter('fares', 'فارس عباد', q: 'فارس عباد', asset: 'assets/reciters/10.png'),
    W2QReciter('qatami', 'ناصر القطامي', q: 'القطامي', asset: 'assets/reciters/11.png'),
    W2QReciter('ahmed-amer', 'أحمد عامر'),
  ];

  static final Map<String, List<W2QTrack>> _mem = {};

  static String _n(String s) => s
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'\s+'), '');

  static Future<List<W2QTrack>> tracks(W2QReciter r,
      {bool refresh = false}) async {
    if (!refresh && _mem.containsKey(r.slug)) return _mem[r.slug]!;

    final cacheName = 'w2q_v2_${r.slug}.json';
    if (!refresh) {
      try {
        final d = await OfflineStore.readJson(cacheName);
        if (d is List && d.isNotEmpty) {
          return _mem[r.slug] = [
            for (final e in d) W2QTrack(e['s'] as int, e['u'] as String),
          ];
        }
      } catch (_) {}
    }

    final list = r.q != null ? await _mp3quran(r) : await _way2quran(r);
    await OfflineStore.writeJson(
        cacheName, [for (final t in list) {'s': t.surah, 'u': t.url}]);
    return _mem[r.slug] = list;
  }

  // ───────────── المصدر الأول: mp3quran.net (API) ─────────────

  static Future<List<W2QTrack>> _mp3quran(W2QReciter r) async {
    final res = await http
        .get(Uri.parse('https://mp3quran.net/api/v3/reciters?language=ar'))
        .timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception('خطأ في الاتصال: ${res.statusCode}');
    }
    final all =
    (jsonDecode(utf8.decode(res.bodyBytes))['reciters'] as List).cast<Map>();

    final q = _n(r.q!);
    final exact = all.where((e) => _n('${e['name']}') == q).toList();
    final found = exact.isNotEmpty
        ? exact
        : all.where((e) => _n('${e['name']}').contains(q)).toList();
    if (found.isEmpty) throw Exception('الشيخ غير موجود في المصدر');

    int total(Map m) => int.tryParse('${m['surah_total']}') ?? 0;
    Map? best;
    for (final m in (found.first['moshaf'] as List).cast<Map>()) {
      final isHafs = m['rewaya_id'] == 1;
      final bestHafs = best != null && best['rewaya_id'] == 1;
      if (best == null ||
          (isHafs && !bestHafs) ||
          (isHafs == bestHafs && total(m) > total(best))) {
        best = m;
      }
    }
    if (best == null) throw Exception('لا توجد تلاوات لهذا الشيخ');

    var server = '${best['server']}';
    if (!server.endsWith('/')) server += '/';

    final list = <W2QTrack>[
      for (final s in '${best['surah_list']}'.split(','))
        if (int.tryParse(s.trim()) != null)
          W2QTrack(int.parse(s.trim()),
              '$server${s.trim().padLeft(3, '0')}.mp3'),
    ]..sort((a, b) => a.surah.compareTo(b.surah));
    if (list.isEmpty) throw Exception('لا توجد سور لهذا الشيخ');
    return list;
  }

  // ───────────── المصدر الثاني: way2quran.com (قراءة الصفحة) ─────────────

  static final _anyMp3 =
  RegExp(r'https?://[^"\s<>\\]+?/(\d{1,3})\.mp3');

  static Future<List<W2QTrack>> _way2quran(W2QReciter r) async {
    final res = await http
        .get(Uri.parse(r.pageUrl), headers: {'User-Agent': 'Mozilla/5.0'})
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('خطأ في الاتصال: ${res.statusCode}');
    }

    final html = utf8
        .decode(res.bodyBytes)
        .replaceAll(r'\/', '/')
        .replaceAll(r'\u002F', '/')
        .replaceAll('&amp;', '&');

    final groups = <String, Map<int, String>>{};

    for (final m in _anyMp3.allMatches(html)) {
      final n = int.parse(m[1]!);

      if (n < 1 || n > 114) continue;

      final url = m[0]!;
      final dir = url.substring(0, url.lastIndexOf('/'));

      groups.putIfAbsent(dir, () => {})[n] = url;
    }

    if (groups.isEmpty) {
      throw Exception('لم أجد روابط صوت في الصفحة (${html.length} حرف)');
    }

    final keys = groups.keys.toList()
      ..sort((a, b) {
        final ha = a.toLowerCase().contains('hafs') ? 1 : 0;
        final hb = b.toLowerCase().contains('hafs') ? 1 : 0;

        if (ha != hb) return hb - ha;

        return groups[b]!.length.compareTo(groups[a]!.length);
      });

    final allTracks = <int, String>{};

    for (final key in keys) {
      for (final entry in groups[key]!.entries) {
        allTracks.putIfAbsent(entry.key, () => entry.value);
      }
    }

    if (allTracks.isEmpty) {
      throw Exception('لا توجد سور لهذا الشيخ');
    }

    return [
      for (final entry in allTracks.entries)
        W2QTrack(entry.key, entry.value),
    ]..sort((a, b) => a.surah.compareTo(b.surah));
  }
}

class _Cancelled {
  const _Cancelled();
}

/// مشغّل التلاوات الصوتية: كائن واحد يبقى يعمل عند مغادرة الصفحات (مثل الراديو)
class SurahAudio extends ChangeNotifier {
  SurahAudio._() {
    _player.playerStateStream.listen((s) {
      _state = s;
      if (s.processingState == ProcessingState.completed) {
        unawaited(stop());
        return;
      }
      notifyListeners();
    });
    _player.currentIndexStream.listen((i) {
      if (i != null && i >= 0 && i < _queue.length) {
        playingSurah = _queue[i].surah;
        notifyListeners();
      }
    });
  }

  static final SurahAudio instance = SurahAudio._();

  final AudioPlayer _player = AudioPlayer();
  PlayerState? _state;
  List<W2QTrack> _queue = [];
  Map<int, String> _names = {};

  W2QReciter? reciter;
  int? playingSurah;
  bool starting = false;

  bool get isPlaying => _state?.playing ?? false;
  String get playingTitle =>
      _names[playingSurah] ?? (playingSurah == null ? '' : 'سورة $playingSurah');

  bool get isLoading {
    final s = _state;
    final buffering = s != null &&
        reciter != null &&
        (s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering);
    return starting || buffering;
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;
  Future<void> seek(Duration d) => _player.seek(d);
  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();

  Future<void> pauseResume() async =>
      isPlaying ? _player.pause() : _player.play();

  Future<String?> play(W2QReciter r, List<W2QTrack> tracks, int index,
      Map<int, String> names) async {
    starting = true;
    notifyListeners();
    try {
      await RadioService.instance.stop(); // مشغّل واحد نشط في كل وقت
      // الصور المحلية لا يمكن عرضها كرابط في الإشعار، فتُترك بدون صورة
      final art = r.asset == null ? Uri.parse(r.imageUrl) : null;
      final sources = <AudioSource>[];
      for (final t in tracks) {
        final local = await localPath(r, t.surah);
        final tag = MediaItem(
          id: '${r.slug}:${t.surah}',
          album: 'اقرأ',
          title: names[t.surah] ?? 'سورة ${t.surah}',
          artist: r.name,
          artUri: art,
        );
        sources.add(local != null
            ? AudioSource.file(local, tag: tag)
            : AudioSource.uri(Uri.parse(t.url), tag: tag));
      }
      reciter = r;
      _queue = tracks;
      _names = names;
      playingSurah = tracks[index].surah;
      await _player.setAudioSources(sources, initialIndex: index);
      unawaited(_player.play());
      return null;
    } on PlayerInterruptedException {
      return null;
    } catch (e) {
      _clear();
      return 'تعذر التشغيل: $e';
    } finally {
      starting = false;
      notifyListeners();
    }
  }

  void _clear() {
    reciter = null;
    playingSurah = null;
    _queue = [];
    notifyListeners();
  }

  Future<void> stop() async {
    _clear();
    await _player.stop();
  }

  // ───────────── التحميل ─────────────

  final Map<String, double> _progress = {};
  final Set<String> _cancel = {};
  final Set<String> _downloaded = {};

  String _key(W2QReciter r, int s) => '${r.slug}:$s';
  String _fileName(int s) => '${s.toString().padLeft(3, '0')}.mp3';

  bool isDownloaded(W2QReciter r, int s) => _downloaded.contains(_key(r, s));
  double? progressOf(W2QReciter r, int s) => _progress[_key(r, s)];

  Future<Directory> _dir(W2QReciter r) async {
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/way2/${r.slug}');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<String?> localPath(W2QReciter r, int s) async {
    final f = File('${(await _dir(r)).path}/${_fileName(s)}');
    return (await f.exists() && await f.length() > 0) ? f.path : null;
  }

  Future<void> refreshDownloaded(W2QReciter r) async {
    final d = await _dir(r);
    _downloaded.removeWhere((k) => k.startsWith('${r.slug}:'));
    await for (final e in d.list()) {
      if (e is File && e.path.endsWith('.mp3')) {
        final n = int.tryParse(e.uri.pathSegments.last.replaceAll('.mp3', ''));
        if (n != null) _downloaded.add(_key(r, n));
      }
    }
    notifyListeners();
  }

  Future<String?> download(W2QReciter r, W2QTrack t) async {
    final key = _key(r, t.surah);
    if (_progress.containsKey(key)) return null;
    _progress[key] = 0;
    _cancel.remove(key);
    notifyListeners();

    final client = http.Client();
    File? tmp;
    try {
      final dir = await _dir(r);
      final target = File('${dir.path}/${_fileName(t.surah)}');
      tmp = File('${target.path}.part');
      final res = await client.send(http.Request('GET', Uri.parse(t.url)));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final total = res.contentLength ?? 0;
      final sink = tmp.openWrite();
      var got = 0;
      try {
        await for (final chunk in res.stream) {
          if (_cancel.contains(key)) throw const _Cancelled();
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) {
            final p = got / total;
            if (p - (_progress[key] ?? 0) > 0.01) {
              _progress[key] = p;
              notifyListeners();
            }
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      await tmp.rename(target.path);
      _downloaded.add(key);
      return null;
    } on _Cancelled {
      await _safeDelete(tmp);
      return null;
    } catch (e) {
      await _safeDelete(tmp);
      return 'تعذر التحميل: $e';
    } finally {
      client.close();
      _progress.remove(key);
      _cancel.remove(key);
      notifyListeners();
    }
  }

  void cancelDownload(W2QReciter r, int s) {
    final key = _key(r, s);
    if (_progress.containsKey(key)) _cancel.add(key);
  }

  Future<void> deleteDownload(W2QReciter r, int s) async {
    final f = File('${(await _dir(r)).path}/${_fileName(s)}');
    await _safeDelete(f);
    _downloaded.remove(_key(r, s));
    notifyListeners();
  }

  Future<void> _safeDelete(File? f) async {
    try {
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }
}