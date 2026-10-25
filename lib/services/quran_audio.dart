import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:iqra/models/ayah.dart';
import 'package:iqra/services/apiService.dart';
import 'package:iqra/services/reciter_settings.dart';
import 'package:iqra/services/reciter_downloads.dart';
import 'package:iqra/services/radio_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:iqra/services/notif_art.dart';

class QuranAudio extends ChangeNotifier {

  static const repeatCount = 1;

  final AudioPlayer _player = AudioPlayer();
  int _session = 0;

  bool isPlaying = false;
  bool isRepeating = false;
  int? playingSurah;
  int? playingAyahNumber;

  void _clear() {
    isPlaying = false;
    isRepeating = false;
    playingSurah = null;
    playingAyahNumber = null;
    notifyListeners();
  }

  Future<bool> _playOnce(Ayah ayah, int session) async {
    final reciter = ReciterSettings.instance.current;
    final local = await ReciterDownloads.instance
        .localPath(reciter.id, ayah.surahNumber, ayah.numberInSurah);
    final source =
        local ?? reciter.urlFor(ayah.surahNumber, ayah.numberInSurah);

    final art = await assetToUri(
        'assets/reciters/${ReciterSettings.instance.selected}.png');

    for (var attempt = 0; attempt < 3; attempt++) {
      if (session != _session) return false;
      try {
        final tag = MediaItem(
          id: '${ayah.surahNumber}:${ayah.numberInSurah}',
          album: 'تطبيق اقرأ',
          title: '${ayah.surahName} - آية ${ayah.numberInSurah}',
          artist: reciter.name,
          artUri: art,
        );
        await _player.setAudioSource(
          local != null
              ? AudioSource.file(local, tag: tag)
              : AudioSource.uri(Uri.parse(source), tag: tag),
        );
        if (session != _session) return false;

        unawaited(_player.play());
        await _player.processingStateStream.firstWhere(
              (s) => s == ProcessingState.completed || s == ProcessingState.idle,
        );
        if (session != _session) return false;

        final completed = _player.processingState == ProcessingState.completed;
        if (completed) return true;
        await _player.pause();
      } on PlayerInterruptedException {
        if (session != _session) return false;
      } on PlayerException catch (e) {
        debugPrint('ayah failed: $source (${e.message})');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return true;
  }

  Future<void> playFromSurah(int startSurah, {int startAyah = 1, bool stopAtSurahEnd = false}) async {
    final session = ++_session;
    unawaited(RadioService.instance.stop());
    isPlaying = true;
    isRepeating = false;
    notifyListeners();
    try {
      for (var surah = startSurah; surah <= 114; surah++) {
        if (session != _session) return;
        final ayahs = await ApiService.getSurahAyahs(surah);
        if (session != _session) return;

        playingSurah = surah;
        notifyListeners();
        if (surah < 114) {
          ApiService.getSurahAyahs(surah + 1).then((_) {}, onError: (_) {});
        }

        // أول سورة تبدأ من الآية المختارة، وما بعدها من أولها
        final fromAyah = surah == startSurah ? startAyah : 1;

        // البسملة فقط عند بداية السورة (عدا الفاتحة والتوبة)
        if (fromAyah == 1 && surah != 1 && surah != 9) {
          playingAyahNumber = null;
          notifyListeners();
          final basmala = Ayah(
            number: 1,
            numberInSurah: 1,
            surahNumber: 1,
            surahName: ayahs.first.surahName,
            text: '',
          );
          if (!await _playOnce(basmala, session)) return;
        }

        for (final ayah in ayahs) {
          if (ayah.numberInSurah < fromAyah) continue;
          if (session != _session) return;
          playingAyahNumber = ayah.number;
          notifyListeners();
          if (!await _playOnce(ayah, session)) return;
        }
        if (stopAtSurahEnd) return;
      }
    } finally {
      if (session == _session) _clear();
      unawaited(_player.pause());
    }
  }

  Future<void> repeatAyah(Ayah ayah, {int times = repeatCount}) async {
    final session = ++_session;
    isPlaying = true;
    isRepeating = true;
    playingSurah = null;
    playingAyahNumber = ayah.number;
    notifyListeners();
    try {
      for (var i = 0; i < times; i++) {
        if (session != _session) return;
        if (!await _playOnce(ayah, session)) return;
      }
    } finally {
      if (session == _session) _clear();
    }
  }

  Future<void> stop() async {
    _session++;
    _clear();
    await _player.stop();
  }

  @override
  void dispose() {
    _session++;
    _player.dispose();
    super.dispose();
  }
}