import 'package:flutter/material.dart';
import 'package:iqra/services/apiService.dart';
import 'package:iqra/services/way2quran_service.dart';
import 'package:iqra/styles/style.dart';

String _digits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

/// صورة الشيخ: مصغّرة، ثم الأصلية، ثم أيقونة
class ReciterPhoto extends StatelessWidget {
  final W2QReciter reciter;
  const ReciterPhoto({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
      color: emerald.withValues(alpha: 0.15),
      child: const Center(
          child: Icon(Icons.person, color: emerald, size: 48)),
    );
    if (reciter.asset != null) {
      return Image.asset(
        reciter.asset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    }
    return Image.network(
      reciter.thumbUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.network(
        reciter.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      ),
    );
  }
}

// ───────────── صفحة الشيوخ ─────────────

class Reciterspage extends StatefulWidget {
  const Reciterspage({super.key});

  @override
  State<Reciterspage> createState() => _ReciterspageState();
}

class _ReciterspageState extends State<Reciterspage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list =
    Way2Quran.reciters.where((r) => r.name.contains(_q)).toList();
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
        title: Text('تلاوات متنوعة', style: titleStyle()),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
      ),
      bottomNavigationBar: const SurahMiniPlayer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              textAlign: TextAlign.right,
              cursorColor: emerald,
              decoration: const InputDecoration(
                hintText: '...ابحث عن شيخ',
                hintStyle: TextStyle(fontFamily: 'ar', color: gold),
                prefixIcon: Icon(Icons.search, color: emerald),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: emerald)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: emerald, width: 2)),
              ),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, i) {
                final r = list[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReciterSurahspage(reciter: r)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ReciterPhoto(reciter: r),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
                              ],
                              stops: const [0.55, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Text(
                            r.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(
                              color: gold,
                              fontSize: 15,
                              fontFamily: 'ar',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ))
          ),
        ],
      ),
    );
  }
}

// ───────────── صفحة سور الشيخ ─────────────

class ReciterSurahspage extends StatefulWidget {
  final W2QReciter reciter;
  const ReciterSurahspage({super.key, required this.reciter});

  @override
  State<ReciterSurahspage> createState() => _ReciterSurahspageState();
}

class _ReciterSurahspageState extends State<ReciterSurahspage> {
  final audio = SurahAudio.instance;
  late Future<(List<W2QTrack>, Map<int, String>)> _future = _load();

  Future<(List<W2QTrack>, Map<int, String>)> _load(
      {bool refresh = false}) async {
    audio.refreshDownloaded(widget.reciter);
    final tracks = await Way2Quran.tracks(widget.reciter, refresh: refresh);
    var names = <int, String>{};
    try {
      final surahs = await ApiService.getSurahs();
      names = {for (final s in surahs) s.number: s.name};
    } catch (_) {}
    return (tracks, names);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onTap(
      List<W2QTrack> tracks, Map<int, String> names, int i) async {
    final t = tracks[i];
    if (audio.reciter?.slug == widget.reciter.slug &&
        audio.playingSurah == t.surah) {
      await audio.pauseResume();
      return;
    }
    final err = await audio.play(widget.reciter, tracks, i, names);
    if (err != null) _snack(err);
  }

  Future<void> _confirmDelete(W2QTrack t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cream,
        title: const Text('حذف التحميل',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'ar', color: emerald)),
        content: const Text('سيُحذف الملف من الهاتف.',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'ar', color: gold)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'ar', color: gold))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: emerald),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style: TextStyle(fontFamily: 'ar', color: cream))),
        ],
      ),
    );
    if (ok == true) await audio.deleteDownload(widget.reciter, t.surah);
  }

  Widget _downloadButton(W2QTrack t) {
    final r = widget.reciter;
    final p = audio.progressOf(r, t.surah);
    if (p != null) {
      return IconButton(
        onPressed: () => audio.cancelDownload(r, t.surah),
        icon: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  value: p > 0 ? p : null, strokeWidth: 2.5, color: emerald),
            ),
            const Icon(Icons.close, size: 12, color: emerald),
          ],
        ),
      );
    }
    if (audio.isDownloaded(r, t.surah)) {
      return IconButton(
        icon: const Icon(Icons.download_done, color: emerald),
        onPressed: () => _confirmDelete(t),
      );
    }
    return IconButton(
      icon: const Icon(Icons.download, color: gold),
      onPressed: () async {
        final err = await audio.download(r, t);
        if (err != null) _snack(err);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reciter;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
        title: Text(r.name,
            style: const TextStyle(
                fontFamily: 'ar', fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
        actions: [
          IconButton(
            tooltip: 'تحديث القائمة',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _load(refresh: true)),
          ),
        ],
      ),
      bottomNavigationBar: const SurahMiniPlayer(),
      body: FutureBuilder<(List<W2QTrack>, Map<int, String>)>(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snap.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      style:
                      FilledButton.styleFrom(backgroundColor: emerald),
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }
          final (tracks, names) = snap.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'السور المتاحة: ${_digits(tracks.length)}',
                  style: const TextStyle(
                      fontFamily: 'ar',
                      fontWeight: FontWeight.bold,
                      color: gold),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: audio,
                  builder: (context, _) => ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, i) {
                      final t = tracks[i];
                      final current = audio.reciter?.slug == r.slug &&
                          audio.playingSurah == t.surah;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: current
                              ? emerald
                              : gold.withValues(alpha: 0.3),
                          child: Text(
                            _digits(t.surah),
                            style: TextStyle(
                                fontFamily: 'ar',
                                fontWeight: FontWeight.bold,
                                color: current ? cream : emerald),
                          ),
                        ),
                        title: Text(
                          names[t.surah] ?? 'سورة ${t.surah}',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontFamily: 'me', color: emerald),
                        ),
                        subtitle: current && audio.isLoading
                            ? const Text('جارٍ التحميل...',
                            style: TextStyle(
                                fontFamily: 'ar', color: gold))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _downloadButton(t),
                            Icon(
                              current && audio.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: emerald,
                              size: 32,
                            ),
                          ],
                        ),
                        onTap: () => _onTap(tracks, names, i),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────── مشغّل مصغّر يظهر أثناء التشغيل ─────────────

class SurahMiniPlayer extends StatelessWidget {
  const SurahMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final a = SurahAudio.instance;
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) {
        final r = a.reciter;
        if (r == null) return const SizedBox.shrink();
        return Material(
          color: emerald,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                            width: 44, height: 44, child: ReciterPhoto(reciter: r)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.playingTitle,
                                maxLines: 1,
                                style: const TextStyle(
                                    fontFamily: 'ar',
                                    fontWeight: FontWeight.bold,
                                    color: cream)),
                            Text(r.name,
                                maxLines: 1,
                                style: const TextStyle(
                                    fontFamily: 'ar',
                                    fontSize: 12,
                                    color: gold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: cream),
                        onPressed: a.previous,
                      ),
                      a.isLoading
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: cream),
                        ),
                      )
                          : IconButton(
                        icon: Icon(
                            a.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: cream),
                        onPressed: a.pauseResume,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: cream),
                        onPressed: a.next,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: cream),
                        onPressed: a.stop,
                      ),
                    ],
                  ),
                  StreamBuilder<Duration>(
                    stream: a.positionStream,
                    builder: (context, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final total = (a.duration?.inMilliseconds ?? 0).toDouble();
                      final maxV = total <= 0 ? 1.0 : total;
                      return SizedBox(
                        height: 28,
                        child: Slider(
                          value: pos.inMilliseconds.toDouble().clamp(0.0, maxV),
                          max: maxV,
                          activeColor: gold,
                          inactiveColor: cream.withValues(alpha: 0.3),
                          onChanged: (v) =>
                              a.seek(Duration(milliseconds: v.toInt())),
                        ),
                      );
                    },
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