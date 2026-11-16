# VYBE — архитектура

> Your sound. Your freedom.
> VYBE — лёгкий open-source клиент для стриминга музыки на Windows, macOS, Linux, Android и iOS.

## 1. Цели

| Цель | Как достигаем |
| --- | --- |
| Одна кодовая база на 5 платформ | Flutter 3.50 (Dart 3.14) |
| Лёгкость | Без своего бэкенда, без Electron/WebView. Плеер на нативных движках: ExoPlayer, AVPlayer, libmpv |
| «Написал название — нашёл трек», как в музыкальных ботах Telegram | Глобальный поиск по всем подключённым источникам из одной строки |
| Рекомендации без сервера | История прослушиваний хранится на устройстве. К ней добавляются «похожие» треки от источников и, по желанию, Last.fm |
| Стильно и user friendly | Дизайн-система из брендбука: тёмная тема, фиолетовый акцент, Poppins. Адаптивный лейаут для десктопа и телефона |

## 2. Слои

```
lib/
├── main.dart                  # инициализация платформ и ProviderScope
├── app.dart                   # MaterialApp + тема
├── core/
│   ├── theme.dart             # дизайн-токены брендбука (цвета, радиусы, шрифт)
│   ├── models.dart            # Track, SourceKind
│   └── format.dart            # форматирование длительностей и т.п.
├── sources/                   # ПОДКЛЮЧАЕМЫЕ ИСТОЧНИКИ МУЗЫКИ
│   ├── music_source.dart      # интерфейс MusicSource
│   ├── youtube_source.dart    # YouTube / YT Music (youtube_explode_dart)
│   ├── local_source.dart      # локальные файлы
│   └── source_registry.dart   # все источники + общий поиск
├── data/
│   └── library_store.dart     # лайки, история, локальная медиатека, настройки (на устройстве)
├── player/
│   └── player_controller.dart # очередь, shuffle/repeat, авто-радио (just_audio)
├── recommendations/
│   ├── recommendation_service.dart  # «Made for You», радио, миксы
│   └── lastfm_client.dart           # необязательно: похожие треки из Last.fm
└── ui/
    ├── shell.dart             # адаптивный каркас: 3 колонки / 2 колонки / мобильный
    ├── screens/               # Home, Search, Library, Settings, Now Playing
    └── widgets/               # сайдбар, плеер-бар, очередь, карточки, строки треков
```

### 2.1 Источники (`MusicSource`)

Каждый источник реализует четыре операции:

```dart
abstract interface class MusicSource {
  SourceKind get kind;
  Future<List<Track>> search(String query);   // поиск по названию
  Future<Uri> resolveStream(Track track);     // прямой URL или файл для плеера
  Future<List<Track>> related(Track track);   // «похожие» для радио и рекомендаций
}
```

Новый источник (SoundCloud, Jamendo, Audius, Navidrome/Subsonic и т.д.) добавляется одним классом
и регистрацией в `SourceRegistry`. UI и плеер при этом не меняются.

Ленивые треки. Трек может прийти из рекомендаций Last.fm, то есть быть только метаданными «артист — название».
Такой трек получает `query` и пустой `id`. При воспроизведении YouTube-источник сам находит лучший
совпадающий ролик. Так рекомендации из любого сервиса превращаются в воспроизводимые треки.

### 2.2 Плеер

- `just_audio`: ExoPlayer на Android, AVPlayer на iOS/macOS.
  `just_audio_media_kit` + libmpv на Windows/Linux.
- Очередь хранится в `PlayerController`. Ссылку на поток получаем только перед воспроизведением,
  потому что ссылки YouTube живут ограниченное время.
- **Авто-радио:** когда очередь заканчивается, плеер добавляет похожие треки, как в YT Music.

### 2.3 Рекомендации (без сервера)

1. **Сигналы**: история прослушиваний (что, когда, дослушано ли) и лайки. Всё хранится на устройстве.
2. **Сиды**: последние и самые частые треки и артисты.
3. **Кандидаты**: `related()` от источников по каждому сиду и, если пользователь указал API-ключ,
   `track.getSimilar` из Last.fm.
4. **Ранжирование**: треки, найденные от нескольких сидов, поднимаются выше. Недавно прослушанные
   отфильтровываются. Подряд не ставятся несколько треков одного артиста.
5. **Миксы на главной** (Chill Vibes, Gaming Mix, Late Night, Workout): настроение и топ-артисты
   пользователя превращаются в поисковые запросы.

Позже можно добавить ListenBrainz (open-source scrobbling) как ещё один источник кандидатов.

## 3. Платформы и дистрибуция

| Платформа | Аудио-движок | Дистрибуция |
| --- | --- | --- |
| Android | ExoPlayer | GitHub Releases (APK), F-Droid / IzzyOnDroid |
| iOS | AVPlayer | Сайдлоад (AltStore / SideStore), TestFlight для сборок без YouTube |
| Windows | libmpv | GitHub Releases (zip / MSIX), winget |
| macOS | AVPlayer | GitHub Releases (dmg), Homebrew cask |
| Linux | libmpv | Flatpak (Flathub), AppImage |

### ⚠️ Про YouTube

Воспроизведение YouTube в стороннем клиенте нарушает Условия использования YouTube. Так же работают
NewPipe, ViMusic и InnerTune. Что из этого следует:

- **App Store и Google Play** с высокой вероятностью отклонят или удалят приложение с YouTube-источником.
  Поэтому основной канал: GitHub Releases, F-Droid, Flathub и сайдлоад на iOS.
- YouTube может в любой момент поменять внутренний API. Тогда нужно обновить зависимость
  `youtube_explode_dart`. Источник изолирован в `youtube_source.dart`, так что поломка не задевает
  остальное приложение.
- Если понадобится версия для магазинов, её можно собрать без YouTube-источника: только локальные файлы,
  свой сервер (Subsonic) и легальные каталоги (Jamendo, Audius).

VYBE не подключает пиратские MP3-сайты и «серые» каталоги, которыми пользуются некоторые музыкальные боты.

## 4. Дизайн-система

Токены перенесены из брендбука в `lib/core/theme.dart`:

| Токен | Значение |
| --- | --- |
| Accent | `#8B5CF6` |
| Accent Light | `#B7A0FF` |
| Surface | `#171722` |
| Surface 2 | `#20202D` |
| Text | `#F4F4F5` |
| Шрифт | Poppins. В Poppins нет кириллицы, поэтому для неё подключён Montserrat |

Логотип (`lib/ui/widgets/logo.dart`) рисуется кодом: две суживающиеся ленты, левая уходит под правую.
Иконки приложения рендерятся из него же: `flutter test tool/render_icons_test.dart --update-goldens`,
затем `dart run flutter_launcher_icons`.

Фото для баннера на главной лежат в `assets/banners/`. Это изображения CC0 из Openverse,
уменьшенные и тонированные в палитру (~60 КБ на кадр).

Адаптивность:

- **≥ 1200 px**: сайдбар, контент, панель «Сейчас играет» с очередью и плеер-бар снизу (как в концепте).
- **720–1200 px**: сайдбар, контент и плеер-бар.
- **< 720 px** (телефон): контент, мини-плеер и нижняя навигация. Полноэкранный плеер открывается по тапу.
