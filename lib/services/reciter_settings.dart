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
    ReciterOption('husary', 'محمود خليل الحصري', 'https://everyayah.com/data/Husary_128kbps_Mujawwad'),
    ReciterOption('abdulbasit', 'عبد الباسط عبدالصمد', 'https://everyayah.com/data/Abdul_Basit_Mujawwad_128kbps'),
    ReciterOption('minshawy','المنشاوي', 'https://everyayah.com/data/Minshawy_Mujawwad_192kbps'),
    ReciterOption('minshawy','(معلم) المنشاوي', 'https://everyayah.com/data/Minshawy_Teacher_128kbps'),
    ReciterOption('muhammad-mahmoud-al-tablawi', 'محمد محمود الطبلاوي', 'https://everyayah.com/data/Mohammad_al_Tablaway_64kbps'),
    ReciterOption('mustafa-ismail', 'مصطفى إسماعيل', 'https://everyayah.com/data/Mustafa_Ismail_48kbps'),
    ReciterOption('jibreel', 'محمد جبريل', 'https://everyayah.com/data/Muhammad_Jibreel_128kbps'),
    ReciterOption('alafasy', 'مشاري العفاسي', 'https://everyayah.com/data/Alafasy_128kbps'),
    ReciterOption('yasser', 'ياسر الدوسري', 'https://everyayah.com/data/Yasser_Ad-Dussary_128kbps'),
    ReciterOption('ajamy', 'أحمد العجمي', 'https://everyayah.com/data/ahmed_ibn_ali_al_ajamy_128kbps'),
    ReciterOption('fares', 'فارس عباد', 'https://everyayah.com/data/Fares_Abbad_64kbps'),
    ReciterOption('qatami', 'ناصر القطامي', 'https://everyayah.com/data/Nasser_Alqatami_128kbps'),
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