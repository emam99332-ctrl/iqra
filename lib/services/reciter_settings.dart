import 'package:flutter/foundation.dart';

class ReciterOption {
  final String id;
  final String name;
  final String baseUrl;
  const ReciterOption(this.id, this.name, this.baseUrl);

  static String fileName(int surah, int ayah) =>
      '${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';

  String urlFor(int surah, int ayah) => '$baseUrl/${fileName(surah, ayah)}';
}

class ReciterSettings extends ChangeNotifier {
  ReciterSettings._();
  static final ReciterSettings instance = ReciterSettings._();

  static const reciters = [
    ReciterOption('husary', 'محمود خليل الحصري', 'https://everyayah.com/data/Husary_64kbps'),
    ReciterOption('alafasy', 'مشاري العفاسي', 'https://everyayah.com/data/Alafasy_128kbps'),
    ReciterOption('abdulbasit', 'عبد الباسط (مرتل)', 'https://everyayah.com/data/Abdul_Basit_Murattal_64kbps'),
    ReciterOption('sudais', 'عبد الرحمن السديس', 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps'),
    ReciterOption('shuraym', 'سعود الشريم', 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps'),
    ReciterOption('minshawy','المنشاوي', 'https://everyayah.com/data/Minshawy_Murattal_128kbps'),
    ReciterOption('abubakr','أبو بكر الشاطري', 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps'),
    ReciterOption('hani','هاني الرفاعي', 'https://everyayah.com/data/Hani_Rifai_192kbps'),
    ReciterOption('yasser', 'ياسر الدوسري', 'https://everyayah.com/data/Yasser_Ad-Dussary_128kbps'),
    ReciterOption('ajamy', 'أحمد العجمي', 'https://everyayah.com/data/ahmed_ibn_ali_al_ajamy_128kbps'),
    ReciterOption('fares', 'فارس عباد', 'https://everyayah.com/data/Fares_Abbad_64kbps'),
    ReciterOption('qatami', 'ناصر القطامي', 'https://everyayah.com/data/Nasser_Alqatami_128kbps'),
    ReciterOption('ghamdi', 'سعد الغامدي', 'https://everyayah.com/data/Ghamadi_40kbps'),
    ReciterOption('alijaber', 'علي جابر', 'https://everyayah.com/data/Ali_Jaber_64kbps'),
  ];

  int _selected = 0;

  int get selected => _selected;
  ReciterOption get current => reciters[_selected];

  void select(int index) {
    if (index == _selected) return;
    _selected = index;
    notifyListeners();
  }
}