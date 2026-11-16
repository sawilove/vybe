// Renders the app icon masters from the logo painter.
// Run: flutter test tool/render_icons_test.dart --update-goldens
// then: dart run flutter_launcher_icons
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vybe/ui/widgets/logo.dart';

Future<void> _render(WidgetTester t, String name, Widget child) async {
  t.view.physicalSize = const Size(1024, 1024);
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(child: SizedBox.square(dimension: 1024, child: child)),
  ));
  await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('../assets/icon/$name.png'));
}

void main() {
  testWidgets('desktop icon (rounded tile)', (t) => _render(t, 'icon', const Center(child: VybeAppIcon(size: 920))));
  testWidgets('square icon (iOS / legacy Android)', (t) => _render(t, 'icon_square', const VybeAppIcon(size: 1024, rounded: false)));
  testWidgets('adaptive foreground', (t) => _render(t, 'icon_foreground', const Center(child: VybeMark(height: 300))));
}
