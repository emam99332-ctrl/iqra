import 'package:flutter/material.dart';
import 'package:iqra/models/surah.dart';
import 'package:iqra/pages/moshafPage.dart';
import 'package:iqra/services/apiService.dart';
import 'package:iqra/styles/style.dart';

class Surahpage extends StatefulWidget {
  const Surahpage({super.key});
@override
  State<Surahpage> createState() => _SurahState();
}

class _SurahState extends State<Surahpage>{
  String removeTashkeel(String text) {
    return text.replaceAll(
      RegExp(r'[\u064B-\u065F\u0670]'),
      '',
    );
  }
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String toArabicNumbers(String text) {
    const english = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < english.length; i++) {
      text = text.replaceAll(english[i], arabic[i]);

    }

    return text;
  }
  String ayahText(int count) {
    if (count > 9) {
      return 'آية';
    } else {
      return 'آيات';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),  
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('القران الكريم',style: titleStyle()),
        foregroundColor: emerald,
        centerTitle: true,
        elevation: 0,
        backgroundColor: cream,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(padding: EdgeInsets.all(12),
          child: TextField(textAlign: TextAlign.right,
            controller: _search,
            cursorColor: emerald,
            style: TextStyle(color: Colors.black),decoration: InputDecoration(
            hintText: '... ابحث عن السورة',
            hintStyle: TextStyle(color: gold, fontFamily: 'ar'),
            prefixIcon: const Icon(
              Icons.search_sharp,
              color: emerald,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: emerald,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: emerald,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: emerald,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: cream,
          ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          ),
          FutureBuilder<List<Surah>>(future: ApiService.getSurahs(), builder: (context, snap){
            if(snap.connectionState == ConnectionState.waiting){
              return Center(child: CircularProgressIndicator(color: emerald,));
            }
            if(snap.hasError){
              return Center(child: Text('${snap.error}', style: TextStyle(fontFamily: 'ar'),));
            }
            final surahs = snap.data!;
            final query = removeTashkeel(_search.text.trim().toLowerCase(),);
            final filteredSurahs = surahs.where((surah) {
              final surahName = removeTashkeel(
                surah.name.toLowerCase(),
              );
              return surahName.contains(query);
            }).toList();
            if (filteredSurahs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد سورة بهذا الاسم',
                  style: TextStyle(
                    fontFamily: 'ar',
                    color: emerald,
                    fontSize: 16,
                  ),
                ),
              );
            }
            return Expanded(child: ListView.builder(
              itemCount: filteredSurahs.length,
              itemBuilder: (context, i) =>

                ListTile(
                  titleAlignment: ListTileTitleAlignment.center,
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: cream,
                    backgroundImage: const AssetImage(
                      'assets/sura_frame.png',
                    ),
                    child: Text(
                      toArabicNumbers(filteredSurahs[i].number.toString()),
                      style: const TextStyle(
                        color: emerald,
                        fontFamily: 'ar',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  title: Text(filteredSurahs[i].name,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: 'me'),
                  ),
                  subtitle: Text(
                    '${toArabicNumbers(filteredSurahs[i].numberOfAyahs.toString())} ${ayahText(filteredSurahs[i].numberOfAyahs)} . ${filteredSurahs[i].isMakkia ? 'مكية' : 'مدنية'}',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: 'ar', color: gold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Moshafpage(initialSurah: filteredSurahs[i].number),
                      ),
                    );
                  },
                ),
              )
            );
          }),
        ],
      ),
    );
  }
}

