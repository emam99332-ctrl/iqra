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
  ];

  static const _titles = [
    'آذان',
    'أسماء الله\n   الحسنى',
    'الراديو',
    'القبلة',
    'اذكار',
  ];

  @override
  void initState() {
    super.initState();
    _prayer.init();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    return hour >= 4 && hour < 12 ? 'صباح الخير' : 'مساء الخير';
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
      width: width * .43,
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('$label ', style: TextStyle(color: cream,fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'ar'),),
              const Icon(Icons.watch_later, color: cream,),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(backgroundColor: cream,
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
                    '${_greeting()}, أخى المسلم',
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
                        prev?.key ?? '—',
                        prev == null ? '—' : formatTime(prev.value),
                        prev == null
                            ? ''
                            : 'منذ ${formatHM(_prayer.now.difference(prev.value))}',
                      ),
                      _prayerBox(
                        width,
                        emerald,
                        'الصلاة الجاية',
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
                builder: (context, _) => RadioService.instance.isPlaying
                    ? Card(
                  child: ListTile(tileColor: gold,
                    leading: const Icon(Icons.radio, color: emerald),
                    title: const Text('الإذاعة تعمل', textAlign: TextAlign.right,style: TextStyle(color: emerald, fontFamily: 'ar', fontWeight: FontWeight.bold),),
                    trailing: IconButton(
                      icon: const Icon(Icons.stop, color: emerald,),
                      onPressed: RadioService.instance.stop,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 3 / 2,
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
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/buttons/$index.png',
                            height: 30,
                            width: 30,
                          ),
                          Text(
                            _titles[index],
                            style: const TextStyle(
                              fontFamily: 'ar',
                              color: cream,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}