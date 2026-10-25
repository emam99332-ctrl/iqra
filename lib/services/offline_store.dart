import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OfflineStore {
  static Future<File> _file(String name) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$name');
  }

  static Future<dynamic> readJson(String name) async {
    final f = await _file(name);
    if (!await f.exists()) return null;
    return jsonDecode(await f.readAsString());
  }

  static Future<void> writeJson(String name, Object data) async {
    final f = await _file(name);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(data));
    await tmp.rename(f.path);
  }
}