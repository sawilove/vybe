import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/library_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows & Linux have no native just_audio backend; use libmpv via media_kit.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
  }

  // Lock screen / notification controls and background playback on mobile & macOS.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'app.vybe.vybe.playback',
      androidNotificationChannelName: 'Playback',
      androidNotificationOngoing: true,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(overrides: [sharedPrefsProvider.overrideWithValue(prefs)], child: const VybeApp()));
}
