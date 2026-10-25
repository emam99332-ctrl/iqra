import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:iqra/models/allah_name.dart';

class NamesService {
  static List<AllahName>? _cache;

  static Future<List<AllahName>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/names.json');
    final decoded = jsonDecode(raw);
    final items = decoded is List
        ? decoded
        : (decoded as Map).values.firstWhere((v) => v is List) as List;
    return _cache = [
      for (var i = 0; i < items.length; i++)
        AllahName.fromJson(items[i] as Map<String, dynamic>, i),
    ];
  }
}