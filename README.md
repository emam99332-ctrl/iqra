# Iqra (اقرأ)

An Android Islamic app built with Flutter: Quran reader with verse-by-verse recitation, prayer times with background Adhan, Qibla compass, Azkar, the 99 Names of Allah, and a live Quran radio.

> **Platform:** Android only. iOS has not been set up (scheduled Adhan and media notifications are configured for Android).

## Features

| Section | Description |
|---|---|
| Quran | Read all 114 surahs in Uthmani script. The text is downloaded once and then works offline. |
| Recitation | Continuous playback from a surah, with Bismillah played before each surah (except Al-Fatihah and At-Tawbah). Multiple reciters. |
| Tap on a verse | Choose to **repeat the verse** (with a `+` / `-` counter) or **play from here to the end of the surah**. |
| Offline audio | Download a reciter's full recitation and listen without internet. |
| Prayer times | Calculated from your location using the Egyptian General Authority method, with a countdown to the next prayer. |
| Adhan | Scheduled notifications that fire at each prayer time, even when the app is closed or the phone is locked. Choose the muezzin from the settings. A full-screen Adhan page with animation and the Adhan words appears on prayer time. |
| Qibla | Compass based on your location and the device sensors. |
| Azkar | Categories of Azkar with a repetition counter. Downloaded once, then offline. |
| Names of Allah | The 99 Names, loaded from a local JSON file. |
| Radio | Live Quran radio from Cairo, with media controls in the notification. |

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible with `sdk: ^3.12.2` (see `pubspec.yaml`)
- Android Studio or the Android SDK
- An Android device or emulator
- Internet on first launch (to download the Quran text and Azkar)

## Getting started

```bash
git clone https://github.com/emam99332-ctrl/iqra.git
cd iqra
flutter pub get
flutter run
```

## Assets that are not included

Some files are not part of the repository for copyright reasons. Add them yourself before running:

| File | Location |
|---|---|
| Adhan audio: `adhan_makkah.mp3`, `adhan_madinah.mp3`, `adhan_alaqsa.mp3`, `adhan_mishary.mp3` | `android/app/src/main/res/raw/` |
| Reciter images `0.png`, `1.png`, ... (one per reciter, in list order) | `assets/reciters/` |
| Fonts: `Amiri-Regular.ttf`, `Sans-Regular.ttf`, `me_quran.ttf`, `Kufi-Bold.ttf` | `assets/fonts/` |
| Radio notification image `r.jpg` | `assets/` |

Adhan file names must be lowercase English letters, digits and underscores only. In code they are referenced without the extension (for example `adhan_makkah`). To add or remove a muezzin, edit the `muezzins` list in `lib/services/adhan_service.dart`.

## Build

```bash
flutter build apk --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`.

Before publishing on Google Play:

- Change `applicationId` in `android/app/build.gradle.kts` (it is currently `com.example.iqra`).
- Create your own signing key. Never commit `key.properties` or any `.jks` / `.keystore` file.
- Review the sensitive permissions below (exact alarms and full-screen intent are checked by Play).

## Permissions

| Permission | Why |
|---|---|
| Internet | Download Quran text, Azkar, recitations and the radio stream |
| Location | Prayer times and Qibla direction |
| Notifications | Adhan alerts |
| Exact alarms / full-screen intent | Fire the Adhan on time and show the Adhan page over the lock screen |
| Foreground service (media playback) | Background audio |
| Boot completed | Reschedule the Adhan after a reboot |

## Data sources

| Source | Used for |
|---|---|
| [alquran.cloud](https://alquran.cloud/api) | Quran text (`quran-uthmani`) and the surah list |
| [everyayah.com](https://everyayah.com) | Verse-by-verse recitations |
| [radio-browser.info](https://www.radio-browser.info) | Stream URL of the Quran radio |
| api.islamic.app | Azkar categories and texts |

The app depends on these external services. If one changes or goes offline, the related feature may stop working. Please review each service's terms of use.

## Tech stack

- **Audio:** `just_audio`, `just_audio_background`, `audio_service`
- **Prayer times:** `adhan`
- **Location and Qibla:** `geolocator`, `geocoding`, `flutter_compass`
- **Adhan scheduling:** `flutter_local_notifications`, `timezone`
- **Storage:** `shared_preferences`, `path_provider`
- **Networking:** `http`

## Project structure

```
lib/
├── main.dart
├── models/        # Ayah, Surah, Azkar, ...
├── pages/         # Home, Moshaf, Azan, Adhan alert/settings, Azkar, Qibla, Radio, ...
├── services/      # API, offline store, audio, prayer times, Adhan scheduling, downloads
├── styles/        # Colors and text styles
└── widgets/       # Reusable widgets
```

## Notes

- Prayer times default to Cairo if the location cannot be determined.
- The Adhan is scheduled for the next 20 days and is refreshed every time the app opens.
- On some devices (Xiaomi, Oppo, Huawei, Samsung) you must disable battery optimization for the app so the Adhan fires reliably in the background.
- The Adhan words shown on the Adhan page are timer-based and not synced to the audio.

## License

No license has been specified yet. All rights to the original project code are reserved by the copyright holder, except where otherwise stated. Third-party assets remain subject to their respective licenses and permissions.
