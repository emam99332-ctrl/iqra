class RadioChannel {
  final String title;
  final String? url;
  const RadioChannel(this.title, this.url);
}

class RadioStation {
  final int id;
  final String name;
  final String url;

  const RadioStation({
    required this.id,
    required this.name,
    required this.url,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) => RadioStation(
    id: int.parse('${json['id']}'),
    name: (json['name'] as String).trim(),
    url: json['url'],
  );
}