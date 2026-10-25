class AzkarCategory {
  final String number;
  final String name;
  final int count;

  const AzkarCategory({
    required this.number,
    required this.name,
    required this.count,
  });

  factory AzkarCategory.fromJson(Map<String, dynamic> json) => AzkarCategory(
    number: '${json['number']}',
    name: json['ar'],
    count: json['count'] ?? 0,
  );
}

class Zikr {
  final String number;
  final String text;
  final int? repeatCount;

  const Zikr({
    required this.number,
    required this.text,
    this.repeatCount,
  });

  factory Zikr.fromJson(Map<String, dynamic> json) => Zikr(
    number: '${json['number']}',
    text: (json['ar']['text'] as String).trim(),
    repeatCount: (json['repeatCount'] as num?)?.toInt(),
  );
}