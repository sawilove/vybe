import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vybe/app.dart';
import 'package:vybe/core/models.dart';
import 'package:vybe/data/library_store.dart';
import 'package:vybe/sources/music_source.dart';
import 'package:vybe/sources/source_registry.dart';

class FakeSource implements MusicSource {
  FakeSource(this.kind);

  @override
  final SourceKind kind;

  final catalog = [
    for (var i = 0; i < 12; i++)
      Track(id: 'id$i', title: 'Song $i', artist: 'Artist ${i % 5}', source: SourceKind.youtube, duration: Duration(seconds: 180 + i)),
  ];

  @override
  Future<List<Track>> search(String query) async => kind == SourceKind.youtube ? catalog : [];

  @override
  Future<List<Track>> related(Track track) async => catalog.reversed.toList();

  @override
  Future<ResolvedStream> resolveStream(Track track) => throw UnimplementedError();
}

Future<void> pumpApp(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      sourceRegistryProvider.overrideWithValue(SourceRegistry([FakeSource(SourceKind.local), FakeSource(SourceKind.youtube)])),
    ],
    child: const VybeApp(googleFonts: false),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final (name, size) in [
    ('desktop', const Size(1672, 941)),
    ('tablet', const Size(1000, 800)),
    ('phone', const Size(390, 844)),
  ]) {
    testWidgets('renders home on $name without overflow', (tester) async {
      await pumpApp(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('Сделано для вас'), findsOneWidget);
      expect(find.text('Chill Vibes'), findsWidgets);
      // Recommendations are loaded from the fake source.
      await tester.scrollUntilVisible(find.text('Song 0'), 200, scrollable: find.descendant(of: find.byKey(const Key('home-list')), matching: find.byType(Scrollable)).first);
      expect(find.text('Song 0'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('search finds tracks across sources', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await tester.tap(find.text('Поиск').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'song');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Найдено: 12'), findsOneWidget);
  });
}
