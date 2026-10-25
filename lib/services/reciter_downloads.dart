import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:iqra/services/apiService.dart';
import 'package:iqra/services/reciter_settings.dart';
import 'package:path_provider/path_provider.dart';

enum DownloadStatus { none, downloading, done }

class ReciterDownloads extends ChangeNotifier {
  ReciterDownloads._();
  static final ReciterDownloads instance = ReciterDownloads._();

  static const _concurrency = 4;

  final Map<String, DownloadStatus> _status = {};
  final Map<String, double> _progress = {};
  final Set<String> _cancelled = {};
  Directory? _root;
  bool _inited = false;

  DownloadStatus statusOf(String id) => _status[id] ?? DownloadStatus.none;
  double progressOf(String id) => _progress[id] ?? 0;

  Future<Directory> _audioRoot() async {
    if (_root != null) return _root!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/audio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _root = dir;
  }

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    final root = await _audioRoot();
    for (final r in ReciterSettings.reciters) {
      final done = await File('${root.path}/${r.id}/done').exists();
      _status[r.id] = done ? DownloadStatus.done : DownloadStatus.none;
    }
    notifyListeners();
  }

  Future<String?> localPath(String id, int surah, int ayah) async {
    final root = await _audioRoot();
    final file = File('${root.path}/$id/${ReciterOption.fileName(surah, ayah)}');
    if (await file.exists() && await file.length() > 0) return file.path;
    return null;
  }

  Future<String?> _fetch(http.Client client, String url, File target) async {
    Object? error;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final res =
        await client.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          final tmp = File('${target.path}.tmp');
          await tmp.writeAsBytes(res.bodyBytes, flush: true);
          await tmp.rename(target.path);
          return null;
        }
        error = 'HTTP ${res.statusCode}';
        if (res.statusCode == 404) break;
      } catch (e) {
        error = e;
      }
      await Future.delayed(Duration(seconds: 1 + attempt));
    }
    return 'تعذر تحميل $url ($error)';
  }

  Future<String?> download(ReciterOption r) async {
    if (statusOf(r.id) == DownloadStatus.downloading) return null;
    _cancelled.remove(r.id);
    _status[r.id] = DownloadStatus.downloading;
    _progress[r.id] = 0;
    notifyListeners();

    final client = http.Client();
    try {
      final surahs = await ApiService.getSurahs();
      final jobs = <(int, int)>[];
      for (final s in surahs) {
        for (var a = 1; a <= s.numberOfAyahs; a++) {
          jobs.add((s.number, a));
        }
      }

      final root = await _audioRoot();
      final dir = Directory('${root.path}/${r.id}');
      if (!await dir.exists()) await dir.create(recursive: true);

      var next = 0;
      var done = 0;
      String? failure;

      Future<void> worker() async {
        while (failure == null && !_cancelled.contains(r.id)) {
          final i = next++;
          if (i >= jobs.length) return;
          final (surah, ayah) = jobs[i];
          final file = File('${dir.path}/${ReciterOption.fileName(surah, ayah)}');
          if (!(await file.exists() && await file.length() > 0)) {
            final err = await _fetch(client, r.urlFor(surah, ayah), file);
            if (err != null) {
              failure = err;
              return;
            }
          }
          done++;
          if (done % 25 == 0 || done == jobs.length) {
            _progress[r.id] = done / jobs.length;
            notifyListeners();
          }
        }
      }

      await Future.wait([for (var i = 0; i < _concurrency; i++) worker()]);

      if (_cancelled.contains(r.id)) {
        _status[r.id] = DownloadStatus.none;
        return null;
      }
      if (failure != null) {
        _status[r.id] = DownloadStatus.none;
        return failure;
      }
      await File('${dir.path}/done').writeAsString('ok');
      _status[r.id] = DownloadStatus.done;
      return null;
    } catch (e) {
      _status[r.id] = DownloadStatus.none;
      return 'تعذر التحميل: $e';
    } finally {
      client.close();
      _progress.remove(r.id);
      notifyListeners();
    }
  }

  void cancel(String id) {
    if (statusOf(id) == DownloadStatus.downloading) _cancelled.add(id);
  }

  Future<void> delete(String id) async {
    final root = await _audioRoot();
    final dir = Directory('${root.path}/$id');
    if (await dir.exists()) await dir.delete(recursive: true);
    _status[id] = DownloadStatus.none;
    notifyListeners();
  }
}