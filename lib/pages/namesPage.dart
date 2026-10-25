import 'package:flutter/material.dart';
import 'package:iqra/models/allah_name.dart';
import 'package:iqra/services/names_service.dart';
import 'package:iqra/styles/style.dart';

String toArabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

class Namespage extends StatelessWidget {
  const Namespage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: cream,
      appBar: AppBar(
        title: Text('أسماء الله الحسنى', style: titleStyle()),
        foregroundColor: emerald,
        backgroundColor: cream,
        centerTitle: true,
      ),
      body: FutureBuilder<List<AllahName>>(
        future: NamesService.load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: emerald,));
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final names = snap.data!;
          return Directionality(
            textDirection: TextDirection.rtl,
            child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: names.length,
            itemBuilder: (context, i) => _NameCard(item: names[i]),
          ));
        },
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final AllahName item;
  const _NameCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(color: emerald,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(backgroundColor: gold,
            title: Column(
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'ar', fontSize: 30, color: emerald),
                ),
                SizedBox(height: 6),
                Text(
                  item.transliteration,
                  textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cream,
                        fontFamily: 'ar',
                        fontSize: 14
                    )
                )
              ],
            ),
            content: Text(item.description, textAlign: TextAlign.end, style: TextStyle(color: cream, fontFamily: 'ar', fontSize: 18, fontWeight: FontWeight.bold),),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(toArabicDigits(item.id), style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cream,
                fontFamily: 'ar',
                fontSize: 16
              )),
              Text(
                item.name,
                style: const TextStyle(fontFamily: 'me', fontSize: 28, color: cream),
              ),
            ],
          ),
        ),
      ),
    );
  }
}