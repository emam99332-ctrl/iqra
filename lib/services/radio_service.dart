
import 'dart:async';
import 'dart:convert';
import 'package:iqra/services/notif_art.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../models/radio_station.dart';

class RadioService extends ChangeNotifier {
  RadioService._() {
    _player.playerStateStream.listen((state) {
      _state = state;
      notifyListeners();
    });
  }

  static const channels = [
    RadioChannel('إذاعة القرآن الكريم من القاهرة', null),
    RadioChannel('تفسير القرآن الكريم', 'https://qurango.net/radio/tafseer'),
    RadioChannel('المختصر في التفسير', 'https://qurango.net/radio/mukhtasartafsir'),
    RadioChannel('المختصر في السيرة النبوية', 'https://qurango.net/radio/almukhtasar_fi_alsiyra'),
    RadioChannel('في ظلال السيرة النبوية', 'https://qurango.net/radio/fi_zilal_alsiyra'),
    RadioChannel('صور من حياة الصحابة', 'https://qurango.net/radio/sahabah'),
  ];

  int selected = 0;
  RadioChannel get channel => channels[selected];

  Future<String?> selectChannel(int i) async {
    if (i == selected) return null;
    final wasPlaying = isPlaying;
    selected = i;
    notifyListeners();
    if (wasPlaying) {
      await _player.stop();
      return toggle();
    }
    return null;
  }

  static final RadioService instance = RadioService._();

  static const _uuid = '8e63e8b6-4e70-4bc0-9f5d-07e8477a4480';

  static const _fallbackUrl =
      'https://stream.radiojar.com/8s5u5tpdtwzuv';

  static const _hosts = [
    'de1.api.radio-browser.info',
    'de2.api.radio-browser.info',
    'all.api.radio-browser.info',
  ];

  final AudioPlayer _player = AudioPlayer();

  PlayerState? _state;
  List<String>? _urls;
  bool _starting = false;

  bool get isStarting => _starting;

  bool get isPlaying => _state?.playing ?? false;

  bool get isLoading {
    final s = _state;

    final buffering = s != null &&
        (s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering);

    return _starting || buffering;
  }

  Future<List<String>> _candidates() async {
    final urls = <String>[];

    for (final host in _hosts) {
      try {
        final res = await http
            .get(
          Uri.parse(
            'https://$host/json/stations/byuuid/$_uuid',
          ),
        )
            .timeout(const Duration(seconds: 8));

        if (res.statusCode != 200) continue;

        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;

        if (list.isEmpty) continue;

        for (final key in ['url_resolved', 'url']) {
          final u = list.first[key];

          if (u is String && u.isNotEmpty && !urls.contains(u)) {
            urls.add(u);
          }
        }

        break;
      } catch (e) {
        debugPrint('Radio host failed: $host ($e)');
      }
    }

    if (!urls.contains(_fallbackUrl)) {
      urls.add(_fallbackUrl);
    }

    return urls;
  }

  Future<String?> toggle() async {
    if (_player.playing) {
      await _player.stop();
      return null;
    }

    _starting = true;
    notifyListeners();

    try {
      final urls = channel.url == null
          ? (_urls ??= await _candidates())
          : [channel.url!];
      final art = await assetToUri('assets/r.jpg');
      for (final url in urls) {
        try {
          await _player.setAudioSource(
            AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: url,
                album: 'تطبيق اقرأ',
                title: channel.title,
                artist: 'اقرأ',
                artUri: art,
              ),
            ),
          );

          unawaited(_player.play());

          return null;
        } on PlayerInterruptedException {
          return null;
        } on PlayerException catch (e) {
          debugPrint('Radio failed: $url (${e.message})');
        }
      }

      _urls = null;

      return 'تعذر تشغيل الإذاعة. الروابط التي تمت تجربتها:\n${urls.join('\n')}';
    } catch (e) {
      _urls = null;
      return 'تعذر تشغيل الإذاعة: $e';
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  Future<void> stop() => _player.stop();
}
