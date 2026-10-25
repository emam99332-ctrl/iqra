import 'package:flutter/material.dart';
import 'package:iqra/models/azkar.dart';
import 'package:iqra/services/apiService.dart';
import 'package:iqra/services/prayer_service.dart';
import 'package:iqra/styles/style.dart';

class Azkarpage extends StatefulWidget {
  const Azkarpage({super.key});

  @override
  State<Azkarpage> createState() => _AzkarpageState();
}

class _AzkarpageState extends State<Azkarpage> {
  late final Future<List<AzkarCategory>> _future;
  String _query = '';

  static const _quick = {
    'أذكار الصباح والمساء': '27',
    'أذكار بعد الصلاة': '25',
    'أذكار النوم': '28',
    'أذكار الاستيقاظ': '1',
  };

  @override
  void initState() {
    super.initState();
    _future = ApiService.getAzkarCategories();
  }

  void _open(String number, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AzkarDetailPage(category: number, title: title),
      ),
    );
  }

  String zekrText(int count) {
    if (count > 9 || count == 1 || count == 2) {
      return 'ذكر';
    } else {
      return 'أذكار';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: cream,
      appBar: AppBar(
        title: Text('الأذكار', style: titleStyle()),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
      ),
      body: FutureBuilder<List<AzkarCategory>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: emerald,));
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final categories =
          snap.data!.where((c) => c.name.contains(_query)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final e in _quick.entries)
                      ActionChip(backgroundColor: gold,

                        label: Text(e.key, style: TextStyle(fontFamily: 'ar', color: emerald, fontWeight: FontWeight.bold),),
                        onPressed: () => _open(e.value, e.key),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  textAlign: TextAlign.right,
                  cursorColor: emerald,
                  decoration: const InputDecoration(
                    hintText: '...ابحث في الأبواب',
                    hintStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ar', color: gold),
                    prefixIcon: Icon(Icons.search, color: gold,),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: emerald),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: emerald,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return ListTile(
                      titleAlignment: ListTileTitleAlignment.center,
                      leading: Text(arabicDigits(c.number.toString()), style: TextStyle(fontFamily: 'ar', color: emerald, fontWeight: FontWeight.bold, fontSize: 20)),
                      title: Text(c.name,textAlign: TextAlign.right, style: TextStyle(fontFamily: 'ar', color: emerald, fontWeight: FontWeight.bold)),
                      subtitle: Text('${arabicDigits(c.count.toString())} ${zekrText(c.count)}', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'ar', color: gold, fontWeight: FontWeight.bold)),
                      onTap: () => _open(c.number, c.name),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AzkarDetailPage extends StatefulWidget {
  final String category;
  final String title;
  const AzkarDetailPage({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<AzkarDetailPage> createState() => _AzkarDetailPageState();
}

class _AzkarDetailPageState extends State<AzkarDetailPage> {
  late final Future<List<Zikr>> _future;
  final Map<int, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _future = ApiService.getAzkar(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: cream,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(fontFamily: 'ar', fontWeight: FontWeight.bold),),
        centerTitle: true,
        foregroundColor: emerald,
        backgroundColor: cream,
      ),
      body: FutureBuilder<List<Zikr>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: emerald,));
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final azkar = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: azkar.length,
            itemBuilder: (context, i) {
              final zikr = azkar[i];
              final target = zikr.repeatCount;
              final count = _counts[i] ?? 0;
              final done = target != null && count >= target;
              return Card(
                color: done ? emerald.withValues(alpha: 0.12) : gold,
                child: InkWell(
                  onTap: done ? null : () => setState(() => _counts[i] = count + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          zikr.text,
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'me',
                            fontSize: 22,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              done
                                  ? 'تم'
                                  : target != null
                                  ? '$count / $target'
                                  : 'العدد: $count',style: TextStyle(color: emerald, fontFamily: 'ar', fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: emerald,),
                              onPressed: () => setState(() => _counts[i] = 0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}