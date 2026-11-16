# Music sources

Every enabled source takes part in search. Sources that need credentials are skipped until you
add them in **Settings → Sources**. Credentials are stored only on your device and are sent only
to the service they belong to.

| Source | Works out of the box | What you need | Full tracks |
| --- | --- | --- | --- |
| YouTube / YT Music | ✅ | — | ✅ |
| Audius | ✅ | — | ✅ |
| Yandex Music | Search only (where Yandex Music is available) | Your OAuth token | With Yandex Plus, otherwise 30 s previews |
| VK | ❌ | Your audio-capable access token | ✅ |
| SoundCloud | ❌ | A client ID | ✅ (some tracks are previews) |
| My files | ✅ | Import files in Library → My files | ✅ |

> VYBE never asks for your password and does not ship anyone's keys. The services below use
> private APIs: they may break, and using them may go against the service's terms. Use your own
> accounts at your own risk.

## YouTube

Nothing to set up. Search falls back to VYBE's own parser if the YouTube library can't read a
result page. Some videos are region-locked; VYBE then tries another upload of the same song.

## Audius

Nothing to set up. Audius is an open, artist-owned catalogue with a public API.

## Yandex Music

1. Sign in to Yandex in your browser.
2. Get an OAuth token for Yandex Music. The open-source
   [yandex-music-api](https://github.com/MarshalX/yandex-music-api) project documents the ways to do
   this (search its docs for "token").
3. Paste the token into **Settings → Sources → Yandex Music token**.

Search works without a token in regions where Yandex Music is available; playback needs the token.
Without a Yandex Plus subscription Yandex serves 30-second previews.

## VK

VK closed its audio API to third-party apps, so only tokens issued for VK's own clients
(for example Kate Mobile or the official app) can access music. Telegram music bots work the same
way: the bot owner's token is used for everyone. In VYBE each user brings their own.

1. Obtain an audio-capable token for your account, for example with the open-source
   [vkaudiotoken](https://github.com/vodka2/vkaudiotoken-python) tool.
2. Paste it into **Settings → Sources → VK access token**.
3. If the tool tells you which app the token belongs to, paste that app's User-Agent too.
   Leave it empty for Kate Mobile.

## SoundCloud

SoundCloud's v2 API needs a client ID. VYBE doesn't ship one.

1. If you have a registered SoundCloud app, use its client ID. Otherwise, open soundcloud.com in your
   browser, open the developer tools → Network tab, play any track and copy the `client_id`
   parameter from a request to `api-v2.soundcloud.com`.
2. Paste it into **Settings → Sources → SoundCloud client ID**.

## Adding a source

Implement `MusicSource` (`lib/sources/music_source.dart`) and add it to `sourceRegistryProvider`
(`lib/sources/source_registry.dart`). See [ARCHITECTURE.md](ARCHITECTURE.md#21-sources-musicsource).
