class Ayah {
  final int number;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final String text;

  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.text,
  });

  static String _letters(String s) =>
      s.replaceAll(RegExp(r'[^\u0621-\u064A]'), '');

  static String _removeBismillah(String text, int surah, int inSurah) {
    if (inSurah != 1 || surah == 1 || surah == 9) return text;
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length > 4 && _letters(words.first) == 'بسم') {
      return words.sublist(4).join(' ');
    }
    return text;
  }

  factory Ayah.fromParts(
      Map<String, dynamic> json,
      int surahNumber,
      String surahName,
      ) {
    final inSurah = json['numberInSurah'] as int;
    return Ayah(
      number: json['number'],
      numberInSurah: inSurah,
      surahNumber: surahNumber,
      surahName: surahName,
      text: _removeBismillah(json['text'], surahNumber, inSurah),
    );
  }

  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah.fromParts(
    json,
    json['surah']['number'],
    json['surah']['name'],
  );
}