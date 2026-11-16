# VYBE

**Your sound. Your freedom.**

VYBE — лёгкий open-source клиент для стриминга музыки на **Windows, macOS, Linux, Android и iOS**.
Напиши название трека, и VYBE найдёт его, как музыкальные боты в Telegram. Дальше он сам подберёт
похожую музыку. Без аккаунтов, без своего сервера: всё хранится на твоём устройстве.

## Возможности

- 🔎 **Поиск в одну строку** сразу по всем источникам: YouTube / YT Music и твоим локальным файлам
- 📻 **Авто-радио**: когда очередь заканчивается, VYBE продолжает похожими треками
- ✨ **Рекомендации без сервера**: «Сделано для вас» и миксы под настроение (Chill, Gaming, Late Night, Workout)
  считаются по истории и лайкам на устройстве. Можно подключить Last.fm для точности
- ❤️ Любимые треки, история, локальная медиатека
- 🎛 Очередь, shuffle, repeat, громкость, горячие клавиши (`/` поиск, `Ctrl+Space` пауза, `Ctrl+←/→`)
- 📱 Адаптивный интерфейс: 3 колонки на десктопе, нижняя навигация и мини-плеер на телефоне

## Сборка

Нужен [Flutter](https://docs.flutter.dev/get-started/install) 3.50+.

```bash
flutter pub get
flutter run            # на подключённом устройстве / десктопе
flutter test           # тесты
```

Linux дополнительно: `sudo apt install libmpv-dev libgtk-3-dev clang cmake ninja-build pkg-config`.

## ⚠️ Про YouTube

Воспроизведение YouTube в сторонних клиентах нарушает Условия использования YouTube (так же работают
NewPipe и InnerTune). Поэтому VYBE распространяется через GitHub Releases, F-Droid, Flathub и сайдлоад на iOS,
а не через App Store / Google Play. Подробнее в [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#-про-youtube).

## Документация

- [Архитектура](docs/ARCHITECTURE.md): слои, источники, плеер, рекомендации, дизайн-система
- [Роадмап](docs/ROADMAP.md)
- Фото баннеров: CC0, см. [assets/banners/CREDITS.md](assets/banners/CREDITS.md)

## Лицензия

[MIT](LICENSE)
