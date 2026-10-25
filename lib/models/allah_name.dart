class AllahName {
  final int id;
  final String name;
  final String transliteration;
  final String description;

  const AllahName({
    required this.id,
    required this.name,
    required this.transliteration,
    required this.description,
  });

  factory AllahName.fromJson(Map<String, dynamic> json, int index) => AllahName(
    id: index + 1,
    name: json['name'],
    transliteration: json['transliteration'],
    description: json['description'] ?? '',
  );
}