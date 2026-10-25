import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<Uri> assetToUri(String asset) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${asset.replaceAll('/', '_')}');
  if (!await file.exists() || await file.length() == 0) {
    final data = await rootBundle.load(asset);
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
  }
  return file.uri;
}