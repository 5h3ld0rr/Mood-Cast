import 'dart:convert';
import 'dart:io';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

void main() async {
  final ytm = await YTMusic.create();
  final results = await ytm.search('ed sheeran', filter: SearchFilter.artists);
  final f = File('test_output.txt');
  if (results.isNotEmpty) {
    f.writeAsStringSync(jsonEncode(results.first) + '\n');
    f.writeAsStringSync('---\n', mode: FileMode.append);
    final browseId = results.first['browseId'];
    if (browseId != null) {
      final artistInfo = await ytm.getArtist(browseId);
      f.writeAsStringSync(jsonEncode(artistInfo), mode: FileMode.append);
    }
  }
}
