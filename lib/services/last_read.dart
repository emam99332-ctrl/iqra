import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastRead extends ChangeNotifier {
  LastRead._();
  static final LastRead instance = LastRead._();

  int? surah;
  int? page; // null لو كنت في وضع السور
  String? surahName;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    surah = p.getInt('lr_surah');
    page = p.getInt('lr_page');
    surahName = p.getString('lr_name');
    notifyListeners();
  }

  Future<void> save({
    required int surah,
    required String name,
    int? page,
  }) async {
    this.surah = surah;
    surahName = name;
    this.page = page;
    notifyListeners();

    final p = await SharedPreferences.getInstance();
    await p.setInt('lr_surah', surah);
    await p.setString('lr_name', name);
    if (page == null) {
      await p.remove('lr_page');
    } else {
      await p.setInt('lr_page', page);
    }
  }
}