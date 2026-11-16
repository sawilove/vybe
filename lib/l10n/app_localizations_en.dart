// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Library';

  @override
  String get navLiked => 'Liked';

  @override
  String get navSettings => 'Settings';

  @override
  String get yourMixes => 'Your mixes';

  @override
  String get madeForYou => 'Made for you';

  @override
  String get recommended => 'Recommended';

  @override
  String get trendingNow => 'Trending now';

  @override
  String get refresh => 'Refresh';

  @override
  String get nothingToRecommend => 'Nothing to recommend yet';

  @override
  String get checkConnection => 'Check your connection or search for a track';

  @override
  String get recommendationsFailed => 'Couldn\'t load recommendations';

  @override
  String get retry => 'Retry';

  @override
  String get recentlyPlayed => 'Recently played';

  @override
  String get seeAll => 'See all';

  @override
  String get back => 'Back';

  @override
  String get forward => 'Next';

  @override
  String get playMix => 'Play mix';

  @override
  String get play => 'Play';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get likedTitle => 'Liked songs';

  @override
  String get likedEmpty => 'Your liked songs will appear here';

  @override
  String get likedEmptyHint =>
      'Tap ♥ on any track. Likes make recommendations better.';

  @override
  String get myFiles => 'My files';

  @override
  String get history => 'History';

  @override
  String get add => 'Add';

  @override
  String get addMusicTitle => 'Add music from your device';

  @override
  String get addMusicHint =>
      'MP3, M4A, FLAC, OGG, OPUS, WAV. The title comes from the file name \"Artist - Title\".';

  @override
  String get chooseFiles => 'Choose files';

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String get clear => 'Clear';

  @override
  String get historyEmpty => 'You haven\'t listened to anything yet';

  @override
  String get mixFailed => 'Couldn\'t build the mix';

  @override
  String get error => 'Error';

  @override
  String get profile => 'Profile';

  @override
  String get yourName => 'What should we call you?';

  @override
  String get playback => 'Playback';

  @override
  String get autoRadio => 'Auto radio';

  @override
  String get autoRadioHint =>
      'When the queue ends, VYBE keeps playing similar tracks';

  @override
  String get recsHint =>
      'Recommendations are computed on this device from your history and likes. A free Last.fm API key makes them better.';

  @override
  String get lastFmKey => 'Last.fm API key (optional)';

  @override
  String get about => 'About';

  @override
  String get aboutText =>
      'VYBE is an open-source music streaming client (MIT). All your data stays on this device.';

  @override
  String get searchAll => 'All';

  @override
  String get searchPrompt => 'Type a track or artist name';

  @override
  String get searchExample =>
      'For example \"Hozier Too Sweet\": VYBE searches every source at once';

  @override
  String get searchError => 'Search failed';

  @override
  String get tryDifferent => 'Try different words';

  @override
  String get searchHint => 'Artists, tracks, playlists…';

  @override
  String get more => 'More';

  @override
  String get willPlayNext => 'Playing next';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get unlike => 'Remove from liked';

  @override
  String get like => 'Add to liked';

  @override
  String get trackRadio => 'Track radio';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get repeatOff => 'Repeat off';

  @override
  String get repeatAll => 'Repeat queue';

  @override
  String get repeatOne => 'Repeat track';

  @override
  String get unmute => 'Unmute';

  @override
  String get mute => 'Mute';

  @override
  String get nothingPlaying => 'Nothing playing';

  @override
  String get queue => 'Queue';

  @override
  String get queueEmpty => 'Queue is empty';

  @override
  String get findingSimilar => 'Finding similar tracks…';

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String get findInSearch => 'Find a track in search';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get upNext => 'Up next';

  @override
  String get downloads => 'Downloads';

  @override
  String get download => 'Download';

  @override
  String get removeDownload => 'Remove download';

  @override
  String get downloading => 'Downloading…';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloadsEmpty => 'No downloads yet';

  @override
  String get downloadsHint =>
      'Download tracks from the ⋮ menu, or like them with auto-download on';

  @override
  String get offline => 'Offline';

  @override
  String get autoDownloadLiked => 'Auto-download liked tracks';

  @override
  String get autoDownloadHint =>
      'Liked tracks are saved for listening without internet';

  @override
  String get clearDownloads => 'Delete all downloads';

  @override
  String get sources => 'Sources';

  @override
  String get sourcesHint =>
      'Every enabled source takes part in search. Credentials stay on this device.';

  @override
  String get needsSetup => 'Needs setup';

  @override
  String get ready => 'Ready';

  @override
  String get yandexToken => 'Yandex Music token';

  @override
  String get yandexHint =>
      'Search works without a token where Yandex Music is available. Playback needs your token; full tracks need Yandex Plus.';

  @override
  String get vkToken => 'VK access token';

  @override
  String get vkUserAgent => 'User-Agent of the token\'s app (optional)';

  @override
  String get vkHint =>
      'VK music only works with a token issued for an official VK client.';

  @override
  String get soundcloudClientId => 'SoundCloud client ID';

  @override
  String get soundcloudHint =>
      'SoundCloud needs a client ID to search and play.';

  @override
  String get howToGet => 'How to get it';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get local => 'My files';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '$count track',
    );
    return '$_temp0';
  }

  @override
  String filesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count files',
      one: 'Added $count file',
    );
    return '$_temp0';
  }

  @override
  String importFailed(String error) {
    return 'Couldn\'t import: $error';
  }

  @override
  String nothingFound(String query) {
    return 'Nothing found for \"$query\"';
  }

  @override
  String sourceUnavailable(String source, String error) {
    return '$source is unavailable: $error';
  }

  @override
  String playbackFailed(String track) {
    return 'Couldn\'t play $track';
  }

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String storageUsed(String size) {
    return 'Used: $size';
  }

  @override
  String greeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Good morning',
      'afternoon': 'Good afternoon',
      'evening': 'Good evening',
      'other': 'Good night',
    });
    return '$_temp0';
  }

  @override
  String mixSubtitle(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'chill': 'Based on your listening',
      'gaming': 'For your gaming session',
      'late': 'For your mood',
      'workout': 'For your workout',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String heroTitle(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'workout': 'Louder!',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String heroSubtitle(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'home': 'Let\'s find something to vibe with…',
      'late': 'Quiet tracks for late hours',
      'workout': 'Energy for workouts and drive',
      'chill': 'Unwind: we picked a calm mix',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get searchOnly => 'Search only';
}
