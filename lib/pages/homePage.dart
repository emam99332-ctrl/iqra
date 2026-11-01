import 'package:flutter/material.dart';
import 'package:iqra/pages/azanPage.dart';
import 'package:iqra/pages/azkarPage.dart';
import 'package:iqra/pages/namesPage.dart';
import 'package:iqra/pages/qiblaPage.dart';
import 'package:iqra/pages/radioPage.dart';
import 'package:iqra/pages/surahPage.dart';
import 'package:iqra/services/prayer_service.dart';
import 'package:iqra/services/radio_service.dart';
import 'package:iqra/styles/style.dart';
import 'package:iqra/widgets/social_footer.dart';
import 'package:iqra/pages/tafsirPage.dart';
import 'package:iqra/pages/recitersPage.dart';
import 'package:iqra/widgets/hijri_card.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _prayer = PrayerService.instance;

  static final List<Widget Function()> _pages = [
        () => Azanpage(),
        () => Namespage(),
        () => Radiopage(),
        () => Qiblapage(),
        () => Azkarpage(),
        () => Tafsirpage(),
  ];

  static const _titles = [
    'آذان',
    'أسماء الله\n  الحسنى',
    'الراديو',
    'القبلة',
    'اذكار',
    'التفسير',
  ];

  @override
  void initState() {
    super.initState();
    _prayer.init();
  }

  Future<void> _onRefresh() async {
    await _prayer.refresh();
    if (!mounted || _prayer.note == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_prayer.note!)),
    );
  }

  Widget _prayerBox(
      double width,
      Color color,
      String label,
      String name,
      String time,
      String info,
      ) {
    return Container(
      height: width * .43,
      width: width * .43,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 3,
            blurRadius: 7,
            offset: Offset(1, 2),
          ),
        ],
        image: DecorationImage(
          image: AssetImage('assets/dashboard.png'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   colors: [
          //     read.withOpacity(.7),
          //     color.withOpacity(.7),
          //   ],
          // ),
          color: color.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    '$label ',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: cream,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'ar',
                    ),
                  ),
                ),
                const Icon(
                  Icons.watch_later,
                  color: cream,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontSize: 25, color: cream, fontFamily: 'ar', fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(time, style: const TextStyle(fontSize: 25, fontFamily: 'ar', color: cream, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(info, style: TextStyle(color: cream, fontFamily: 'ar'),),
          ],
        ),

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      bottomNavigationBar: const SurahMiniPlayer(),
      backgroundColor: cream,
      appBar: null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "اِقـــرأ",
                  style: titGreenleStyle(),
                ),
              ),
              const SizedBox(height: 30),
              ListenableBuilder(
                listenable: _prayer,
                builder: (context, _) => Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    textAlign: TextAlign.right,
                    'السلام عليكم ورحمة الله وبركاته, أخى المسلم',
                    style: titleStyle(),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _prayer,
                      builder: (context, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _prayer.refreshing
                              ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: emerald,
                              ),
                            ),
                          )
                              : IconButton(
                            icon: const Icon(Icons.refresh, color: emerald,),
                            onPressed: _onRefresh,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_prayer.placeName, style: titleGeo()),
                              const Icon(Icons.location_on_rounded, color: emerald,),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              HijriCard(height: width * 2.5, width: width),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: _prayer,
                builder: (context, _) {
                  final prev = _prayer.previous;
                  final next = _prayer.next;
                  return Row(
                    children: [
                      _prayerBox(
                        width,
                        gold,
                        'الصلاة السابقة',
                        prev?.key ?? '_',
                        prev == null ? '—' : formatTime(prev.value),
                        prev == null
                            ? ''
                            : 'منذ ${formatHM(_prayer.now.difference(prev.value))}',
                      ),
                      const SizedBox(width: 20),
                      _prayerBox(
                        width,
                        emerald,
                        'الصلاة القادمة',
                        next?.key ?? '—',
                        next == null ? '—' : formatTime(next.value),
                        next == null
                            ? ''
                            : 'بعد ${formatHM(_prayer.remaining)}',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: width * .35,
                width: width,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: emerald,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Surahpage()),
                    );
                  },
                  child: Row(
                    children: [
                      const Text(
                        'القرأن الكريم  ',
                        style: TextStyle(
                          fontFamily: 'ar',
                          fontSize: 30,
                          color: cream,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Image.asset(
                        'assets/qlogo.png',
                        width: width * .25,
                        height: width * .25,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: RadioService.instance,
                builder: (context, i) => RadioService.instance.isPlaying
                    ? Card(
                  child: ListTile(tileColor: gold,
                    leading: const Icon(Icons.radio, color: emerald),
                    title: Text(
                      RadioService.instance.channel.title,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: emerald,
                          fontFamily: 'ar',
                          fontWeight: FontWeight.bold)
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.stop, color: emerald,),
                      onPressed: RadioService.instance.stop,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 3 / 2.5,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: emerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _pages[index](),
                          ),
                        );
                      },
                      child: Column(mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/buttons/$index.png',
                            height: 60,
                            width: 60,
                          ),
                          Text(
                            _titles[index],
                            style: const TextStyle(
                              fontFamily: 'ar',
                              color: read,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: width * .35,
                width: width,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: emerald,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Reciterspage()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'تلاوات متنوعة ',
                        style: TextStyle(
                            fontFamily: 'ar',
                            fontSize: 30,
                            color: cream,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      Image.asset(
                        'assets/6.png',
                        width: width * .25,
                        height: width * .25,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SocialFooter(),
            ],
          ),
        ),
      ),
    );
  }
}