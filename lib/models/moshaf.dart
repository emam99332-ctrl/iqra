class Moshaf {
  final int id;
  final String name;
  final String server;
  final List<int> surahList;

  const Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahList,
  });

  factory Moshaf.fromJson(Map<String, dynamic> json) => Moshaf(
    id: json['id'],
    name: json['name'],
    server: json['server'],
    surahList: (json['surah_list'] as String)
        .split(',')
        .map(int.parse)
        .toList(),
  );

  String audioUrl(int surahId) =>
      '$server${surahId.toString().padLeft(3, '0')}.mp3';
}

class Reciter {
  final int id;
  final String name;
  final List<Moshaf> moshafs;

  const Reciter({
    required this.id,
    required this.name,
    required this.moshafs,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) => Reciter(
    id: json['id'],
    name: json['name'],
    moshafs: (json['moshaf'] as List)
        .map((m) => Moshaf.fromJson(m))
        .toList(),
  );
}