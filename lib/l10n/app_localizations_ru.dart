// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get navHome => 'Главная';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navLibrary => 'Медиатека';

  @override
  String get navLiked => 'Любимые';

  @override
  String get navSettings => 'Настройки';

  @override
  String get yourMixes => 'Ваши миксы';

  @override
  String get madeForYou => 'Сделано для вас';

  @override
  String get recommended => 'Рекомендации';

  @override
  String get trendingNow => 'Популярное сейчас';

  @override
  String get refresh => 'Обновить';

  @override
  String get nothingToRecommend => 'Пока нечего рекомендовать';

  @override
  String get checkConnection =>
      'Проверьте подключение к интернету или найдите трек в поиске';

  @override
  String get recommendationsFailed => 'Не удалось загрузить рекомендации';

  @override
  String get retry => 'Повторить';

  @override
  String get recentlyPlayed => 'Недавно слушали';

  @override
  String get seeAll => 'Все';

  @override
  String get back => 'Назад';

  @override
  String get forward => 'Вперёд';

  @override
  String get playMix => 'Слушать микс';

  @override
  String get play => 'Слушать';

  @override
  String get shuffle => 'Перемешать';

  @override
  String get likedTitle => 'Любимые треки';

  @override
  String get likedEmpty => 'Здесь будут ваши любимые треки';

  @override
  String get likedEmptyHint =>
      'Нажмите ♥ у любого трека. Лайки помогают точнее подбирать рекомендации.';

  @override
  String get myFiles => 'Мои файлы';

  @override
  String get history => 'История';

  @override
  String get add => 'Добавить';

  @override
  String get addMusicTitle => 'Добавьте музыку с устройства';

  @override
  String get addMusicHint =>
      'MP3, M4A, FLAC, OGG, OPUS, WAV. Название берётся из имени файла «Артист - Трек».';

  @override
  String get chooseFiles => 'Выбрать файлы';

  @override
  String get removeFromLibrary => 'Убрать из медиатеки';

  @override
  String get clear => 'Очистить';

  @override
  String get historyEmpty => 'Вы ещё ничего не слушали';

  @override
  String get mixFailed => 'Не удалось собрать микс';

  @override
  String get error => 'Ошибка';

  @override
  String get profile => 'Профиль';

  @override
  String get yourName => 'Как к вам обращаться?';

  @override
  String get playback => 'Воспроизведение';

  @override
  String get autoRadio => 'Авто-радио';

  @override
  String get autoRadioHint =>
      'Когда очередь закончится, VYBE продолжит похожими треками';

  @override
  String get recsHint =>
      'Рекомендации считаются прямо на устройстве по вашей истории и лайкам. Бесплатный ключ Last.fm API делает их точнее.';

  @override
  String get lastFmKey => 'Ключ Last.fm API (необязательно)';

  @override
  String get about => 'О приложении';

  @override
  String get aboutText =>
      'VYBE — open-source клиент для стриминга музыки (MIT). Все данные хранятся только на этом устройстве.';

  @override
  String get searchAll => 'Все';

  @override
  String get searchPrompt => 'Напишите название трека или артиста';

  @override
  String get searchExample =>
      'Например, «Hozier Too Sweet»: VYBE ищет сразу во всех источниках';

  @override
  String get searchError => 'Ошибка поиска';

  @override
  String get tryDifferent => 'Попробуйте написать иначе';

  @override
  String get searchHint => 'Артисты, треки, плейлисты…';

  @override
  String get more => 'Ещё';

  @override
  String get willPlayNext => 'Будет следующим';

  @override
  String get addedToQueue => 'Добавлено в очередь';

  @override
  String get playNext => 'Играть следующим';

  @override
  String get addToQueue => 'Добавить в очередь';

  @override
  String get unlike => 'Убрать из любимых';

  @override
  String get like => 'В любимые';

  @override
  String get trackRadio => 'Радио по треку';

  @override
  String get previous => 'Предыдущий';

  @override
  String get next => 'Следующий';

  @override
  String get repeatOff => 'Повтор выключен';

  @override
  String get repeatAll => 'Повтор очереди';

  @override
  String get repeatOne => 'Повтор трека';

  @override
  String get unmute => 'Включить звук';

  @override
  String get mute => 'Выключить звук';

  @override
  String get nothingPlaying => 'Ничего не играет';

  @override
  String get queue => 'Очередь';

  @override
  String get queueEmpty => 'Очередь пуста';

  @override
  String get findingSimilar => 'Подбираем похожие треки…';

  @override
  String get removeFromQueue => 'Убрать из очереди';

  @override
  String get findInSearch => 'Найдите трек в поиске';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get upNext => 'Далее';

  @override
  String get downloads => 'Загрузки';

  @override
  String get download => 'Скачать';

  @override
  String get removeDownload => 'Удалить загрузку';

  @override
  String get downloading => 'Скачивается…';

  @override
  String get downloaded => 'Скачано';

  @override
  String get downloadsEmpty => 'Загрузок пока нет';

  @override
  String get downloadsHint =>
      'Скачивайте треки через меню ⋮ или ставьте лайк при включённой автозагрузке';

  @override
  String get offline => 'Офлайн';

  @override
  String get autoDownloadLiked => 'Автоматически скачивать любимые треки';

  @override
  String get autoDownloadHint =>
      'Лайкнутые треки сохраняются для прослушивания без интернета';

  @override
  String get clearDownloads => 'Удалить все загрузки';

  @override
  String get sources => 'Источники';

  @override
  String get sourcesHint =>
      'Все включённые источники участвуют в поиске. Ключи хранятся только на этом устройстве.';

  @override
  String get needsSetup => 'Нужна настройка';

  @override
  String get ready => 'Готов';

  @override
  String get yandexToken => 'Токен Яндекс Музыки';

  @override
  String get yandexHint =>
      'Поиск работает без токена там, где доступна Яндекс Музыка. Для воспроизведения нужен ваш токен, для полных треков — Яндекс Плюс.';

  @override
  String get vkToken => 'Токен доступа ВК';

  @override
  String get vkUserAgent => 'User-Agent приложения токена (необязательно)';

  @override
  String get vkHint =>
      'Музыка ВК работает только с токеном, выданным для официального клиента ВК.';

  @override
  String get soundcloudClientId => 'Client ID SoundCloud';

  @override
  String get soundcloudHint =>
      'Для поиска и воспроизведения SoundCloud нужен client ID.';

  @override
  String get howToGet => 'Как получить';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get local => 'Мои файлы';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count трека',
      many: '$count треков',
      few: '$count трека',
      one: '$count трек',
    );
    return '$_temp0';
  }

  @override
  String filesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавлено $count файла',
      many: 'Добавлено $count файлов',
      few: 'Добавлено $count файла',
      one: 'Добавлен $count файл',
    );
    return '$_temp0';
  }

  @override
  String importFailed(String error) {
    return 'Не удалось импортировать: $error';
  }

  @override
  String nothingFound(String query) {
    return 'Ничего не нашли по «$query»';
  }

  @override
  String sourceUnavailable(String source, String error) {
    return '$source недоступен: $error';
  }

  @override
  String playbackFailed(String track) {
    return 'Не удалось воспроизвести: $track';
  }

  @override
  String downloadFailed(String error) {
    return 'Не удалось скачать: $error';
  }

  @override
  String storageUsed(String size) {
    return 'Занято: $size';
  }

  @override
  String greeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Доброе утро',
      'afternoon': 'Добрый день',
      'evening': 'Добрый вечер',
      'other': 'Доброй ночи',
    });
    return '$_temp0';
  }

  @override
  String mixSubtitle(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'chill': 'По вашим прослушиваниям',
      'gaming': 'Для игровой сессии',
      'late': 'Под настроение',
      'workout': 'Для тренировки',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String heroTitle(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'workout': 'Громче!',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String heroSubtitle(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'home': 'Давайте найдём что-нибудь под настроение…',
      'late': 'Тихие треки для поздних часов',
      'workout': 'Энергия для тренировки и драйва',
      'chill': 'Расслабься — мы подобрали спокойный микс',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get searchOnly => 'Только поиск';
}
