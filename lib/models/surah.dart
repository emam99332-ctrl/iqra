class Surah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  final bool isMakkia;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
    required this.isMakkia,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
    number: json['number'],
    name: json['name'],
    englishName: json['englishName'],
    numberOfAyahs: json['numberOfAyahs'],
    isMakkia: json['revelationType'] == 'Meccan',
  );
}