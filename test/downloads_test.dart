import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vybe/core/models.dart';
import 'package:vybe/data/download_manager.dart';
import 'package:vybe/data/library_store.dart';
import 'package:vybe/sources/music_source.dart';
import 'package:vybe/sources/source_registry.dart';

class _FakeSource extends MusicSource {
  @override
  SourceKind get kind => SourceKind.audius;
  @override
  Future<List<Track>> search(String query) async => [];
  @override
  Future<List<Track>> related(Track track) async => [];
  @override
  Future<ResolvedStream> resolveStream(Track track) => throw UnimplementedError();
  @override
  Future<DownloadResult> download(Track track, String basePath, {http.Client? client}) async {
    final f = File('$basePath.mp3')..writeAsStringSync('audio');
    return DownloadResult(track, f.path);
  }
}

void main() {
  late Directory tmp;
  late ProviderContainer c;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('vybe_dl');
    DownloadManager.directory = () async => tmp;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        sourceRegistryProvider.overrideWithValue(SourceRegistry([_FakeSource()])),
      ],
    );
    c.listen(downloadsProvider, (_, _) {});
  });
  tearDown(() {
    c.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<void> settle() async {
    for (var i = 0; i < 20 && c.read(downloadsProvider).queued.isNotEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  const track = Track(id: 'a1', title: 'Song', artist: 'Artist', source: SourceKind.audius);

  test('downloads a track and remembers where it is', () async {
    c.read(downloadsProvider.notifier).enqueue(track);
    await settle();
    final path = c.read(downloadsProvider).pathFor(track);
    expect(path, isNotNull);
    expect(File(path!).readAsStringSync(), 'audio');

    await c.read(downloadsProvider.notifier).remove(track);
    expect(c.read(downloadsProvider).isDownloaded(track), isFalse);
    expect(File(path).existsSync(), isFalse);
  });

  test('liking a track downloads it when auto-download is on', () async {
    c.read(libraryProvider.notifier).toggleLike(track);
    await settle();
    expect(c.read(downloadsProvider).isDownloaded(track), isTrue);
  });

  test('no auto-download when the setting is off', () async {
    final lib = c.read(libraryProvider.notifier);
    lib.updateSettings(c.read(libraryProvider).settings.copyWith(autoDownloadLiked: false));
    lib.toggleLike(track);
    await settle();
    expect(c.read(downloadsProvider).isDownloaded(track), isFalse);
  });
}
