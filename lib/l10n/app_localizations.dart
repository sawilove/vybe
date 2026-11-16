import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get navLiked;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @yourMixes.
  ///
  /// In en, this message translates to:
  /// **'Your mixes'**
  String get yourMixes;

  /// No description provided for @madeForYou.
  ///
  /// In en, this message translates to:
  /// **'Made for you'**
  String get madeForYou;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending now'**
  String get trendingNow;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @nothingToRecommend.
  ///
  /// In en, this message translates to:
  /// **'Nothing to recommend yet'**
  String get nothingToRecommend;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection or search for a track'**
  String get checkConnection;

  /// No description provided for @recommendationsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load recommendations'**
  String get recommendationsFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @recentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get recentlyPlayed;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get forward;

  /// No description provided for @playMix.
  ///
  /// In en, this message translates to:
  /// **'Play mix'**
  String get playMix;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @likedTitle.
  ///
  /// In en, this message translates to:
  /// **'Liked songs'**
  String get likedTitle;

  /// No description provided for @likedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your liked songs will appear here'**
  String get likedEmpty;

  /// No description provided for @likedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap ♥ on any track. Likes make recommendations better.'**
  String get likedEmptyHint;

  /// No description provided for @myFiles.
  ///
  /// In en, this message translates to:
  /// **'My files'**
  String get myFiles;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'Add music from your device'**
  String get addMusicTitle;

  /// No description provided for @addMusicHint.
  ///
  /// In en, this message translates to:
  /// **'MP3, M4A, FLAC, OGG, OPUS, WAV. The title comes from the file name \"Artist - Title\".'**
  String get addMusicHint;

  /// No description provided for @chooseFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose files'**
  String get chooseFiles;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get removeFromLibrary;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t listened to anything yet'**
  String get historyEmpty;

  /// No description provided for @mixFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t build the mix'**
  String get mixFailed;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get yourName;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @autoRadio.
  ///
  /// In en, this message translates to:
  /// **'Auto radio'**
  String get autoRadio;

  /// No description provided for @autoRadioHint.
  ///
  /// In en, this message translates to:
  /// **'When the queue ends, VYBE keeps playing similar tracks'**
  String get autoRadioHint;

  /// No description provided for @recsHint.
  ///
  /// In en, this message translates to:
  /// **'Recommendations are computed on this device from your history and likes. A free Last.fm API key makes them better.'**
  String get recsHint;

  /// No description provided for @lastFmKey.
  ///
  /// In en, this message translates to:
  /// **'Last.fm API key (optional)'**
  String get lastFmKey;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'VYBE is an open-source music streaming client (MIT). All your data stays on this device.'**
  String get aboutText;

  /// No description provided for @searchAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchAll;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a track or artist name'**
  String get searchPrompt;

  /// No description provided for @searchExample.
  ///
  /// In en, this message translates to:
  /// **'For example \"Hozier Too Sweet\": VYBE searches every source at once'**
  String get searchExample;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchError;

  /// No description provided for @tryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try different words'**
  String get tryDifferent;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Artists, tracks, playlists…'**
  String get searchHint;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @willPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Playing next'**
  String get willPlayNext;

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get addedToQueue;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @unlike.
  ///
  /// In en, this message translates to:
  /// **'Remove from liked'**
  String get unlike;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Add to liked'**
  String get like;

  /// No description provided for @trackRadio.
  ///
  /// In en, this message translates to:
  /// **'Track radio'**
  String get trackRadio;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat queue'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat track'**
  String get repeatOne;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get nothingPlaying;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get queueEmpty;

  /// No description provided for @findingSimilar.
  ///
  /// In en, this message translates to:
  /// **'Finding similar tracks…'**
  String get findingSimilar;

  /// No description provided for @removeFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get removeFromQueue;

  /// No description provided for @findInSearch.
  ///
  /// In en, this message translates to:
  /// **'Find a track in search'**
  String get findInSearch;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get removeDownload;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloading;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get downloadsEmpty;

  /// No description provided for @downloadsHint.
  ///
  /// In en, this message translates to:
  /// **'Download tracks from the ⋮ menu, or like them with auto-download on'**
  String get downloadsHint;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @autoDownloadLiked.
  ///
  /// In en, this message translates to:
  /// **'Auto-download liked tracks'**
  String get autoDownloadLiked;

  /// No description provided for @autoDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'Liked tracks are saved for listening without internet'**
  String get autoDownloadHint;

  /// No description provided for @clearDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloads'**
  String get clearDownloads;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @sourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Every enabled source takes part in search. Credentials stay on this device.'**
  String get sourcesHint;

  /// No description provided for @needsSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs setup'**
  String get needsSetup;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @yandexToken.
  ///
  /// In en, this message translates to:
  /// **'Yandex Music token'**
  String get yandexToken;

  /// No description provided for @yandexHint.
  ///
  /// In en, this message translates to:
  /// **'Search works without a token where Yandex Music is available. Playback needs your token; full tracks need Yandex Plus.'**
  String get yandexHint;

  /// No description provided for @vkToken.
  ///
  /// In en, this message translates to:
  /// **'VK access token'**
  String get vkToken;

  /// No description provided for @vkUserAgent.
  ///
  /// In en, this message translates to:
  /// **'User-Agent of the token\'s app (optional)'**
  String get vkUserAgent;

  /// No description provided for @vkHint.
  ///
  /// In en, this message translates to:
  /// **'VK music only works with a token issued for an official VK client.'**
  String get vkHint;

  /// No description provided for @soundcloudClientId.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud client ID'**
  String get soundcloudClientId;

  /// No description provided for @soundcloudHint.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud needs a client ID to search and play.'**
  String get soundcloudHint;

  /// No description provided for @howToGet.
  ///
  /// In en, this message translates to:
  /// **'How to get it'**
  String get howToGet;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'My files'**
  String get local;

  /// No description provided for @trackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} track} other{{count} tracks}}'**
  String trackCount(int count);

  /// No description provided for @filesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added {count} file} other{Added {count} files}}'**
  String filesAdded(int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import: {error}'**
  String importFailed(String error);

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for \"{query}\"'**
  String nothingFound(String query);

  /// No description provided for @sourceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{source} is unavailable: {error}'**
  String sourceUnavailable(String source, String error);

  /// No description provided for @playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play {track}'**
  String playbackFailed(String track);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'Used: {size}'**
  String storageUsed(String size);

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'{part, select, morning{Good morning} afternoon{Good afternoon} evening{Good evening} other{Good night}}'**
  String greeting(String part);

  /// No description provided for @mixSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{id, select, chill{Based on your listening} gaming{For your gaming session} late{For your mood} workout{For your workout} other{}}'**
  String mixSubtitle(String id);

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'{id, select, workout{Louder!} other{}}'**
  String heroTitle(String id);

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{id, select, home{Let\'s find something to vibe with…} late{Quiet tracks for late hours} workout{Energy for workouts and drive} chill{Unwind: we picked a calm mix} other{}}'**
  String heroSubtitle(String id);

  /// No description provided for @searchOnly.
  ///
  /// In en, this message translates to:
  /// **'Search only'**
  String get searchOnly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
