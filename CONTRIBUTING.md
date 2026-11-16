# Contributing to VYBE

Thanks for helping! Issues and pull requests are welcome.

## Setup

1. Install [Flutter 3.50+](https://docs.flutter.dev/get-started/install).
   On Linux also: `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libmpv-dev`.
2. `flutter pub get`
3. `flutter run`

## Before opening a pull request

```bash
flutter gen-l10n
dart format -l 120 lib test tool
flutter analyze
flutter test
```

- **Language:** code, comments, docs and commit messages are in English.
- **UI strings** go to `lib/l10n/app_en.arb` *and* `lib/l10n/app_ru.arb`; never hard-code text in widgets.
  Use `context.l10n.yourKey`.
- **Changelog:** add a line under `## [Unreleased]` in `CHANGELOG.md` for anything users will notice.
- **New music source:** see [docs/SOURCES.md](docs/SOURCES.md#adding-a-source). Never commit API keys,
  tokens or client IDs, and don't add piracy sites.
- **Design:** follow the brand book tokens in `lib/core/theme.dart` and the glass accents in
  `lib/ui/widgets/glass.dart`.

## Project layout

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Releases are described in
[docs/RELEASING.md](docs/RELEASING.md).
