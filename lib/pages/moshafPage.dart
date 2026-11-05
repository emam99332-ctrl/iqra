import 'package:flutter/material.dart';
import 'package:iqra/models/ayah.dart';
import 'package:iqra/services/apiService.dart';
import 'package:iqra/services/quran_audio.dart';
import 'package:flutter/gestures.dart';
import 'package:iqra/widgets/reciter_card.dart';
import 'package:iqra/services/reciter_settings.dart';
import 'package:iqra/styles/style.dart';
import 'package:iqra/services/reciter_downloads.dart';

import '../services/tafsir_service.dart';
import 'package:iqra/services/last_read.dart';

String toArabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

/// رقم صفحة بداية كل سورة في مصحف المدينة (604 صفحة)
const List<int> kSurahStartPage = [
  1, 2, 50, 77, 106, 128, 151, 177, 187, 208,
  221, 235, 249, 255, 262, 267, 282, 293, 305, 312,
  322, 332, 342, 350, 359, 367, 377, 385, 396, 404,
  411, 415, 418, 428, 434, 440, 446, 453, 458, 467,
  477, 483, 489, 496, 499, 502, 507, 511, 515, 518,
  520, 523, 526, 528, 531, 534, 537, 542, 545, 549,
  551, 553, 554, 556, 558, 560, 562, 564, 566, 568,
  570, 572, 574, 575, 577, 578, 580, 582, 583, 585,
  586, 587, 587, 589, 590, 591, 591, 592, 593, 594,
  595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
  600, 600, 601, 601, 601, 602, 602, 602, 603, 603,
  603, 604, 604, 604,
];

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
        padding: EdgeInsets.only(bottom: 10),
        child: Image.asset('assets/Basmala.png')
    );
  }
}

class ImageTextFrame extends StatelessWidget {
  final String text;
  final String imagePath;
  final TextStyle? textStyle;

  const ImageTextFrame({
    super.key,
    required this.text,
    this.imagePath = 'assets/frame.png',
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return  Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          imagePath,
        ),
        Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: textStyle ??
                const TextStyle(
                  fontFamily: 'me',
                  color: cream,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}

class Moshafpage extends StatefulWidget {
  final int initialSurah;
  final int? initialPage;

  const Moshafpage({super.key, this.initialSurah = 1, this.initialPage});

  @override
  State<Moshafpage> createState() => _MoshafPageState();
}

class _MoshafPageState extends State<Moshafpage> {
  late PageController _controller; // شلنا final عشان نبدّلها
  final QuranAudio _audio = QuranAudio();
  late int _current;
  int? _lastAudioSurah;
  String _title = '';
  bool _byPage = false; // false = بالسور، true = بالصفحات (604)
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _current = widget.initialSurah;
    _byPage = widget.initialPage != null;
    _page = widget.initialPage ?? 1;
    _controller = PageController(
      initialPage: _byPage ? _page - 1 : widget.initialSurah - 1,
    );
    _audio.addListener(_onAudioChanged);
    _byPage ? _updatePageTitle(_page) : _updateTitle(_current);
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
    if (!_byPage &&
        _lastAudioSurah != null &&
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
      LastRead.instance.save(surah: surah, name: ayahs.first.surahName); // جديد
    } catch (_) {}
  }

  Future<void> _updatePageTitle(int page) async {
    try {
      final ayahs = await ApiService.getPageAyahs(page);
      if (!mounted || page != _page) return;
      setState(() {
        _current = ayahs.first.surahNumber;
        _title = ayahs.first.surahName;
      });
      LastRead.instance.save(
        surah: ayahs.first.surahNumber,
        name: ayahs.first.surahName,
        page: page,
      ); // جديد
    } catch (_) {}
  }

  void _toggleMode() {
    final old = _controller;
    setState(() {
      _byPage = !_byPage;
      if (_byPage) {
        _page = kSurahStartPage[_current - 1];
        _controller = PageController(initialPage: _page - 1);
      } else {
        _controller = PageController(initialPage: _current - 1);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    _byPage ? _updatePageTitle(_page) : _updateTitle(_current);
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
    final tafsirFuture = TafsirService.ayah(
        TafsirService.current.id, ayah.surahNumber, ayah.numberInSurah);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<String>(
                    future: tafsirFuture,
                    builder: (context, snap) => Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          snap.connectionState == ConnectionState.waiting
                              ? 'جارٍ تحميل التفسير...'
                              : snap.hasError
                              ? 'تعذر تحميل التفسير (تحتاج إنترنت أول مرة)'
                              : '${TafsirService.current.name}:\n${snap.data}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                              fontFamily: 'ar', fontSize: 15, color: emerald),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: read,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
        backgroundColor: read,
        foregroundColor: emerald,
        centerTitle: true,
        title: Text(
          _title,
          style: titleStyle(),
        ),
        actions: [
          IconButton(
            tooltip: _byPage ? 'عرض بالسور' : 'عرض بالصفحات',
            icon: Icon(_byPage ? Icons.list_alt : Icons.menu_book),
            onPressed: _toggleMode,
          ),
          IconButton(
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
                                          reverse: true,
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
        key: ValueKey(_byPage), // يجبره يتبني من جديد عند التبديل
        controller: _controller,
        reverse: true,
        itemCount: _byPage ? 604 : 114,
        onPageChanged: (i) {
          if (_byPage) {
            setState(() => _page = i + 1);
            _updatePageTitle(_page);
          } else {
            setState(() => _current = i + 1);
            _updateTitle(_current);
          }
        },
        itemBuilder: (context, i) => _byPage
            ? MushafPageView(
          page: i + 1,
          audio: _audio,
          onAyahTap: _onAyahTap,
        )
            : SurahView(
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
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: ListenableBuilder(
            listenable: widget.audio,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ImageTextFrame(text: ayahs.first.surahName,),
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

class MushafPageView extends StatefulWidget {
  final int page;
  final QuranAudio audio;
  final void Function(Ayah ayah) onAyahTap;
  const MushafPageView({
    super.key,
    required this.page,
    required this.audio,
    required this.onAyahTap,
  });

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  late final Future<List<Ayah>> _future;
  final Map<int, TapGestureRecognizer> _taps = {};

  TapGestureRecognizer _tapFor(Ayah a) => _taps.putIfAbsent(
    a.number,
        () => TapGestureRecognizer()..onTap = () => widget.onAyahTap(a),
  );

  @override
  void initState() {
    super.initState();
    _future = ApiService.getPageAyahs(widget.page);
  }

  @override
  void dispose() {
    for (final r in _taps.values) {
      r.dispose();
    }
    super.dispose();
  }

  TextSpan _span(Ayah a) => TextSpan(
    text: '${a.text} ﴿${toArabicDigits(a.numberInSurah)}﴾ ',
    recognizer: _tapFor(a),
    style: widget.audio.playingAyahNumber == a.number
        ? TextStyle(
      backgroundColor:
      (widget.audio.isRepeating ? gold : emerald)
          .withValues(alpha: 0.25),
    )
        : null,
  );

  Widget _block(List<TextSpan> spans) => Text.rich(
    TextSpan(children: spans),
    textAlign: TextAlign.justify,
    textDirection: TextDirection.rtl,
    style: const TextStyle(fontFamily: 'Amiri', fontSize: 24, height: 2),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ayah>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: emerald));
        }
        if (snap.hasError) return Center(child: Text('${snap.error}'));

        final ayahs = snap.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: ListenableBuilder(
            listenable: widget.audio,
            builder: (context, _) {
              final children = <Widget>[];
              final spans = <TextSpan>[];

              for (final a in ayahs) {
                if (a.numberInSurah == 1) {
                  // سورة جديدة في نص الصفحة: اقفل الفقرة اللي قبلها وحط الإطار
                  if (spans.isNotEmpty) {
                    children.add(_block(List.of(spans)));
                    spans.clear();
                  }
                  children.add(ImageTextFrame(text: a.surahName));
                  if (a.surahNumber != 1 && a.surahNumber != 9) {
                    children.add(const BismillahHeader());
                  }
                }
                spans.add(_span(a));
              }
              if (spans.isNotEmpty) children.add(_block(spans));

              children.add(
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      toArabicDigits(widget.page),
                      style: const TextStyle(
                        fontFamily: 'ar',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: emerald,
                      ),
                    ),
                  ),
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              );
            },
          ),
        );
      },
    );
  }
}