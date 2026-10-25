import 'package:flutter/material.dart';
import 'package:iqra/models/ayah.dart';
import 'package:iqra/services/apiService.dart';
import 'package:iqra/services/quran_audio.dart';
import 'package:flutter/gestures.dart';
import 'package:iqra/widgets/reciter_card.dart';
import 'package:iqra/services/reciter_settings.dart';
import 'package:iqra/styles/style.dart';
import 'package:iqra/services/reciter_downloads.dart';

const bismillah = 'بــِسْم ٱلـلـَّهِ ٱلـرَّحـْمـَٰنِ ٱلـرَّحِيمِ';

String toArabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

Future<bool?> _confirm(
    BuildContext context,
    String title,
    String message,
    String action,
    ) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(backgroundColor: cream,
      title: Text(title, textAlign: TextAlign.right, style: TextStyle(fontFamily: 'ar',color: gold, ),),
      content: Text(message, textAlign: TextAlign.right,style: TextStyle(fontFamily: 'ar', color: gold)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('إلغاء', style: TextStyle(color: gold, fontFamily: 'ar'),),
        ),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: gold),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action, style: TextStyle(color: emerald, fontFamily: 'ar', fontWeight: FontWeight.bold),),
        ),
      ],
    ),
  );
}

Future<void> _onDownloadTap(BuildContext context, ReciterOption r) async {
  final downloads = ReciterDownloads.instance;
  switch (downloads.statusOf(r.id)) {
    case DownloadStatus.downloading:
      {
        downloads.cancel(r.id);
        return;
      }
    case DownloadStatus.done:
      {
        final ok = await _confirm(
          context,
          'حذف التحميل',
          'سيتم حذف تلاوة الشيخ${r.name}.',
          'حذف',
        );
        if (ok == true) await downloads.delete(r.id);
        return;
      }
    case DownloadStatus.none:
      {
        final ok = await _confirm(
          context,
          'تحميل التلاوة كاملة',
          'تلاوة الشيخ ${r.name} كاملة حجمها كبير. '
          'هل انت متاكد؟ '
          'يرجى ترك التطبيق مفتوح حتى الانتهاء',
          'تحميل',
        );
        if (ok != true) return;
        final error = await downloads.download(r);
        if (error == null || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
  }
}

bool startsWithBismillah(Ayah a) =>
    a.numberInSurah == 1 && a.surahNumber != 1 && a.surahNumber != 9;

class BismillahHeader extends StatelessWidget {
  const BismillahHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Image.asset('assets/Basmala.png')
    );
  }
}

class Moshafpage extends StatefulWidget {

  final int initialSurah;
  const Moshafpage({super.key, this.initialSurah = 1});

  @override
  State<Moshafpage> createState() => _MoshafPageState();
}

class _MoshafPageState extends State<Moshafpage> {
  late final PageController _controller;
  final QuranAudio _audio = QuranAudio();
  late int _current;
  int? _lastAudioSurah;
  String _title = '';

  @override
  void initState() {
    super.initState();
    _current = widget.initialSurah;
    _controller = PageController(initialPage: widget.initialSurah - 1);
    _audio.addListener(_onAudioChanged);
    _updateTitle(_current);
    ReciterDownloads.instance.init();
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioChanged);
    _audio.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onAudioChanged() {
    final surah = _audio.playingSurah;
    if (surah == null) {
      _lastAudioSurah = null;
      return;
    }
    if (_lastAudioSurah != null &&
        surah != _lastAudioSurah &&
        _current == _lastAudioSurah &&
        _controller.hasClients) {
      _controller.animateToPage(
        surah - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
    _lastAudioSurah = surah;
  }

  Future<void> _updateTitle(int surah) async {
    try {
      final ayahs = await ApiService.getSurahAyahs(surah);
      if (!mounted || surah != _current) return;
      setState(() => _title = ayahs.first.surahName);
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (_audio.isPlaying) {
      await _audio.stop();
      return;
    }
    try {
      await _audio.playFromSurah(_current);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تشغيل الصوت: $e')),
      );
    }
  }

  Future<void> _onAyahTap(Ayah ayah) async {
    int times = 3;
    await showModalBottomSheet(
      context: context,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'آية ${toArabicDigits(ayah.numberInSurah)} - ${ayah.surahName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'ar',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: emerald),
                ),
                const SizedBox(height: 16),
                const Text('عدد مرات التكرار',
                    style: TextStyle(
                        fontFamily: 'ar',
                        fontWeight: FontWeight.bold,
                        color: gold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(
                          backgroundColor: emerald, foregroundColor: cream),
                      icon: const Icon(Icons.remove),
                      onPressed: times > 1
                          ? () => setSheet(() => times--)
                          : null,
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        toArabicDigits(times),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'ar',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: emerald),
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                          backgroundColor: emerald, foregroundColor: cream),
                      icon: const Icon(Icons.add),
                      onPressed: times < 99
                          ? () => setSheet(() => times++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: emerald),
                  icon: const Icon(Icons.repeat, color: cream),
                  label: Text('تكرار الآية ${toArabicDigits(times)} مرات',
                      style: const TextStyle(
                          fontFamily: 'ar', color: cream)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await _audio.repeatAyah(ayah, times: times);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تعذر تشغيل الصوت: $e')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: gold),
                  icon: const Icon(Icons.play_arrow, color: emerald),
                  label: const Text('ابدأ القراءة من هنا',
                      style: TextStyle(
                          fontFamily: 'ar',
                          fontWeight: FontWeight.bold,
                          color: emerald)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await _audio.playFromSurah(
                        ayah.surahNumber,
                        startAyah: ayah.numberInSurah,
                        stopAtSurahEnd: true,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تعذر تشغيل الصوت: $e')),
                      );
                    }
                  },
                ),
                if (_audio.isPlaying) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.stop, color: emerald),
                    label: const Text('إيقاف التشغيل',
                        style: TextStyle(fontFamily: 'ar', color: emerald)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _audio.stop();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: emerald,
        centerTitle: true,
        title: Text(_title, style: titleStyle()),
        actions: [IconButton(
            icon: Icon(Icons.headset_rounded),
            onPressed: (){
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return FractionallySizedBox(
                    heightFactor: 0.33,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Center(
                          child: Padding(padding: EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Align(alignment: Alignment.topRight ,child: Text('القراء', style: TextStyle(fontFamily: 'ar', fontWeight: FontWeight.bold, color: emerald, fontSize: 22))),
                                SizedBox(
                                  height: 200,
                                  child: ListenableBuilder(
                                    listenable: Listenable.merge([
                                      ReciterSettings.instance,
                                      ReciterDownloads.instance,
                                    ]),
                                    builder: (context, _) {
                                      final settings = ReciterSettings.instance;
                                      final downloads = ReciterDownloads.instance;
                                      return GridView.builder(
                                        padding: const EdgeInsets.all(12),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: ReciterSettings.reciters.length,
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 1,
                                          mainAxisSpacing: 6,
                                          crossAxisSpacing: 6,
                                          childAspectRatio: 1.5,
                                        ),
                                        itemBuilder: (context, i) {
                                          final r = ReciterSettings.reciters[i];
                                          return ReciterCard(
                                            image: 'assets/reciters/$i.png',
                                            name: r.name,
                                            selected: settings.selected == i,
                                            onTap: () => settings.select(i),
                                            downloadStatus: downloads.statusOf(r.id),
                                            downloadProgress: downloads.progressOf(r.id),
                                            onDownloadTap: () => _onDownloadTap(context, r),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),)
                      ),
                    ),
                  );
                },
              );
            }
        ),
          ListenableBuilder(
            listenable: _audio,
            builder: (context, _) => IconButton(
              icon: Icon(_audio.isPlaying ? Icons.stop : Icons.play_arrow),
              onPressed: _togglePlay,
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        reverse: true,
        itemCount: 114,
        onPageChanged: (i) {
          setState(() => _current = i + 1);
          _updateTitle(_current);
        },
        itemBuilder: (context, i) => SurahView(
            surah: i + 1,
            audio: _audio,
            onAyahTap: _onAyahTap,
        ),
      ),
    );
  }
}

class SurahView extends StatefulWidget {
  final int surah;
  final QuranAudio audio;
  final void Function(Ayah ayah) onAyahTap;
  const SurahView({
    super.key,
    required this.surah,
    required this.audio,
    required this.onAyahTap,
  });

  @override
  State<SurahView> createState() => _SurahViewState();
}

class _SurahViewState extends State<SurahView> {
  late final Future<List<Ayah>> _future;
  final Map<int, TapGestureRecognizer> _taps = {};

  TapGestureRecognizer _tapFor(Ayah a) => _taps.putIfAbsent(
    a.number,
        () => TapGestureRecognizer()..onTap = () => widget.onAyahTap(a),
  );

  @override
  void initState() {
    super.initState();
    _future = ApiService.getSurahAyahs(widget.surah);
  }

  @override
  void dispose() {
    for (final r in _taps.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ayah>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: emerald,));
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        final ayahs = snap.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ListenableBuilder(
            listenable: widget.audio,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.surah != 1 && widget.surah != 9)
                  const BismillahHeader(),
                Text.rich(
                  TextSpan(
                    children: [
                      for (final a in ayahs)
                        TextSpan(
                          text:
                          '${a.text} ﴿${toArabicDigits(a.numberInSurah)}﴾ ',
                          recognizer: _tapFor(a),
                          style: widget.audio.playingAyahNumber == a.number
                              ? TextStyle(
                            backgroundColor: (widget.audio.isRepeating
                                ? gold
                                : emerald)
                                .withValues(alpha: 0.25),
                          )
                              : null,
                        ),
                    ],
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 24,
                    height: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}