# Architecture

> VYBE is a lightweight open-source music streaming client for Windows, macOS, Linux, Android and iOS.

## 1. Goals

| Goal | How |
| --- | --- |
| One codebase, five platforms | Flutter 3.50 (Dart 3.14) |
| Lightweight | No backend, no Electron/WebView. Native audio engines: ExoPlayer, AVPlayer, libmpv |
| "Type the name, get the track", like Telegram music bots | One search box that queries every enabled source at once |
| Recommendations without a server | Listening history stays on the device and is combined with "related" tracks from sources and, optionally, Last.fm |
| Stylish and friendly | Design system from the brand book: dark theme, violet accent, Poppins, glass accents. Adaptive layouts for desktop and phone |
| Works offline | Downloads are cached on the device; liked tracks are downloaded automatically |
| English and Russian | `flutter gen-l10n` with ARB files; the repository itself is English-only |

## 2. Layers

```
lib/
├── main.dart                  # platform init (libmpv, background audio) + ProviderScope
├── app.dart                   # MaterialApp, theme, localization
├── core/
│   ├── theme.dart             # brand book design tokens (colours, radii, fonts)
│   ├── models.dart            # Track, SourceKind
│   ├── format.dart            # durations, part of day
│   └── version.dart           # app version (kept in sync with pubspec.yaml)
├── l10n/                      # app_en.arb, app_ru.arb (+ generated code)
├── sources/                   # PLUGGABLE MUSIC SOURCES
│   ├── music_source.dart      # MusicSource base class
│   ├── youtube_source.dart    # YouTube / YT Music
│   ├── yandex_source.dart     # Yandex Music (user token)
│   ├── vk_source.dart         # VK (user token)
│   ├── soundcloud_source.dart # SoundCloud (user client ID)
│   ├── audius_source.dart     # Audius (open API)
│   ├── local_source.dart      # files on the device
│   └── source_registry.dart   # all sources + combined search
├── data/
│   ├── library_store.dart     # likes, history, local files, settings (on device)
│   └── download_manager.dart  # offline cache
├── player/
│   └── player_controller.dart # queue, shuffle/repeat, auto radio (just_audio)
├── recommendations/
│   ├── recommendation_service.dart  # "Made for you", radio, mixes
│   └── lastfm_client.dart           # optional: similar tracks from Last.fm
└── ui/
    ├── shell.dart             # adaptive shell: 3 columns / 2 columns / phone
    ├── screens/               # home, search, library, settings, mix
    └── widgets/               # logo, glass accents, player, track rows
```

### 2.1 Sources (`MusicSource`)

```dart
abstract class MusicSource {
  SourceKind get kind;
  bool get isConfigured;                          // false → skipped by search
  Future<List<Track>> search(String query);       // free-text search
  Future<ResolvedStream> resolveStream(Track t);  // URL or file for the player
  Future<List<Track>> related(Track t);           // for radio and recommendations
  Future<DownloadResult> download(Track t, String basePath); // offline cache
}
```

A new source is one class plus one line in `SourceRegistry`; the UI and player don't change.
Search runs every **enabled and configured** source in parallel; a failing source never breaks
search, it is shown as "unavailable" next to the results. See [SOURCES.md](SOURCES.md) for each
source and how to connect your accounts.

**Lazy tracks.** A recommendation can be metadata only ("artist — title", e.g. from Last.fm).
Such a track has an empty `id` and a `query`; the source finds the best match right before playing.

### 2.2 Player

- `just_audio`: ExoPlayer on Android, AVPlayer on iOS/macOS, `just_audio_media_kit` + libmpv on Windows/Linux.
- Background playback and lock screen controls on Android/iOS/macOS via `just_audio_background`.
- The queue lives in `PlayerController`. Stream URLs are resolved right before playing because
  YouTube links expire. Downloaded tracks play from disk.
- **Auto radio:** when the queue ends, similar tracks are appended, like YT Music.

### 2.3 Offline cache

`DownloadManager` downloads one track at a time into the app support directory and keeps an
index in `SharedPreferences`. Liked tracks are queued automatically when
*Settings → Offline → Auto-download liked tracks* is on (default). The player always prefers the
offline copy.

### 2.4 Recommendations (no server)

1. **Signals:** listening history and likes, stored on the device.
2. **Seeds:** recent and frequent tracks and artists.
3. **Candidates:** `related()` from sources for every seed, plus Last.fm `track.getSimilar` when
   the user added an API key.
4. **Ranking:** tracks suggested by several seeds rank higher, recently played ones are dropped,
   and the same artist never plays twice in a row.
5. **Mood mixes** (Chill Vibes, Gaming Mix, Late Night, Workout): mood keywords combined with the
   user's top artists.

## 3. Platforms and distribution

VYBE is distributed through **GitHub Releases** only (see [RELEASING.md](RELEASING.md)).

| Platform | Audio engine | Release artifact |
| --- | --- | --- |
| Android | ExoPlayer | APK |
| iOS | AVPlayer | Unsigned IPA (sideload with AltStore / SideStore) |
| Windows | libmpv | zip |
| macOS | AVPlayer | zip with the .app (unsigned) |
| Linux | libmpv | tar.gz |

### About YouTube, VK and Yandex Music

Playing YouTube in a third-party client is against YouTube's Terms of Service; NewPipe, ViMusic
and InnerTune work the same way. VK and Yandex Music are used through unofficial APIs with the
user's **own** account. Consequences:

- App stores would reject such an app, so VYBE ships through GitHub Releases.
- Those services can change their private APIs at any time. Every source is isolated in its own
  file, so a breakage never takes the rest of the app down.
- VYBE never ships anyone's credentials and never asks for passwords: users paste tokens they
  obtained themselves (see [SOURCES.md](SOURCES.md)). It does not use piracy sites.

## 4. Design system

Tokens from the brand book live in `lib/core/theme.dart`:

| Token | Value |
| --- | --- |
| Accent | `#8B5CF6` |
| Accent Light | `#B7A0FF` |
| Surface | `#171722` |
| Surface 2 | `#20202D` |
| Text | `#F4F4F5` |
| Font | Poppins (Montserrat as the Cyrillic fallback: Poppins has no Cyrillic) |

**Logo** (`lib/ui/widgets/logo.dart`) reproduces the brand book mark. Its outline was traced from
the brand book PNG (marching squares on an 8× mask, 70 points, Catmull-Rom spline with a sharp
corner at the V's notch); the fold lines come from an edge map and the colours were sampled from
the original. App icons are rendered from it:
`flutter test tool/render_icons_test.dart --update-goldens`, then `dart run flutter_launcher_icons`.

**Glass accents** (`lib/ui/widgets/glass.dart`): a 1 px iridescent rim that lights up at one corner,
a soft corner glow, a glass sheen with a glowing edge, bottom-corner waves and an ambient window glow.

**Banner photos** (`assets/banners/`) are CC0 images from Openverse, resized and tinted into the
palette (~60 KB each). Credits: [assets/banners/CREDITS.md](../assets/banners/CREDITS.md).

**Layouts:**

- **≥ 1200 px:** sidebar, content, "Now playing" panel with the queue, player bar.
- **720–1200 px:** sidebar, content, player bar.
- **< 720 px (phone):** content, mini player and bottom navigation; full-screen player on tap.
