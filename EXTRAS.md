# Extras setup (Themes · Daily history · Firebase · Ads · IAP)

## Already working offline

- **Themes** — Ocean / Midnight / Ember free; Aurora / Noir / Solar via Theme Pack
- **Daily history** — last 90 clears + streak on Home
- **Leaderboard** — local board (with seed rivals) until Firebase is enabled
- **Ads** — Google **test** AdMob IDs (banner, rewarded hint, interstitial every 3 wins)
- **IAP** — Remove Ads + Theme Pack (debug unlock if store products missing)

## 1) Firebase leaderboard (live)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

1. Replace `lib/firebase/firebase_options.dart` with the generated file  
2. Set `AppConfig.firebaseEnabled = true` in `lib/config/app_config.dart`  
3. Firebase Console → Authentication → enable **Anonymous**  
4. Firestore → create DB → collection `leaderboard`  
5. Add Android `google-services.json` / iOS `GoogleService-Info.plist` if not added by the CLI  

Suggested Firestore rules (tighten later):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /leaderboard/{uid} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## 2) Production ads

In `lib/config/app_config.dart` replace all `ca-app-pub-3940…` test IDs with your AdMob app + unit IDs.  
Also update:

- Android: `AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
- iOS: `Info.plist` → `GADApplicationIdentifier`

## 3) Production IAP

Create non-consumables in Play Console / App Store Connect:

| Product ID | Purpose |
|---|---|
| `arrows_remove_ads` | Remove banner + interstitials |
| `arrows_theme_pack` | Unlock premium themes |

IDs are defined in `AppConfig`. Debug builds can unlock without the store.

## 4) Privacy

Before store submit, add a privacy policy URL covering ads, analytics/Firebase, and purchases.

---

# Release checklist

The Mac this was developed on runs Xcode 15.2 and can no longer build for the
App Store, so the **iOS** store build goes through Codemagic
(`codemagic.yaml`). **Android** is built here with `tool/build_release.sh`.
`flutter run --release` still works locally for on-device testing.

## Done in the repo

- Android release signing reads `android/key.properties`; falls back to debug
  keys when that file is absent, so local release runs keep working
- R8 minify + resource shrinking on release builds (`proguard-rules.pro`)
- `ios/Runner/PrivacyInfo.xcprivacy` (declared: no tracking, device ID for
  third-party advertising, UserDefaults `CA92.1`)
- `ITSAppUsesNonExemptEncryption = false` in `Info.plist`
- `codemagic.yaml` with an `ios-release` workflow (IPA → TestFlight)
- `tool/build_release.sh` for the Play bundle — refuses to build without a
  keystore, and always passes `--dart-define=LIVE_ADS=true`
- `tool/generate_icons.py` regenerates every app-icon size from one script

## Still needed before going live

### 1. AdMob — done

Live IDs are in `lib/config/app_config.dart`, `AndroidManifest.xml`
(`APPLICATION_ID`) and `Info.plist` (`GADApplicationIdentifier`).

Live ads are **opt-in per build**: only builds passing
`--dart-define=LIVE_ADS=true` serve them, and the Codemagic workflows do that.
Everything else — including `flutter run --release` for on-device testing —
gets Google's sample units, so you can never tap your own live ads by accident
(which can get an AdMob account suspended).

`AppConfig.testDeviceIds` is a second safety net for forcing test ads on a
specific device even in a live build.

### 2. Android keystore — one command, then you are done

```bash
keytool -genkey -v -keystore ~/arrows-release.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias arrows
```

Then `cp android/key.properties.example android/key.properties` and fill it in.
PKCS12 keystores use one password for both `storePassword` and `keyPassword`.

**Back up the `.jks` and its password.** Lose them and you can't sign updates
with that key again. (With Play App Signing this is only the *upload* key,
which Google can reset — but treat it as irreplaceable anyway.)

Build the bundle with `./tool/build_release.sh`, which prints the signing
certificate so you can confirm the right key was used.

### 3. In-app purchases

Create `arrows_remove_ads` and `arrows_theme_pack` as non-consumables in App
Store Connect and Play Console. Until they exist StoreKit answers
`storekit_no_response` and the Shop shows no prices.

### 4. Codemagic setup (iOS only)

Signing needs an Apple Developer Portal key under Settings > Integrations >
Developer Portal, with the App Manager or Admin role. The key in use is named
`codemagic-admin` (Key ID 2CNWYY478P) and `codemagic.yaml` names it directly.
That key is account-wide and shared with the other apps in this Codemagic
account, so rename it there and their builds break — change the name in
`codemagic.yaml` instead.

The app record must already exist in App Store Connect. Android needs nothing
here — it ships from this Mac.

### 5. Store paperwork

Privacy policy URL (required — the app serves ads and sells IAP), Data Safety
form, privacy nutrition labels, screenshots, description, content rating.

### 6. Android toolchain — pinned to API 36

`android/app/build.gradle` is at `compileSdk`/`targetSdk 36`, above Flutter
3.24.5's defaults, for two reasons that arrived together:

- Play has required **target API 36** for new apps and updates since
  2026-08-31. A bundle at 35 is rejected.
- `in_app_update` 4.2.5 compiles against SDK 36 and ships the Kotlin 2.2
  stdlib. The old Kotlin 1.9.24 compiler could not read its metadata
  ("binary version of its metadata is 2.2.0, expected version is 1.9.0"), so
  `bundleRelease` failed outright.

That forced the toolchain up as a set, since each step has a floor:

| | Was | Now |
|---|---|---|
| Kotlin | 1.9.24 | 2.2.10 |
| AGP | 8.3.2 | 8.9.1 |
| Gradle wrapper | 8.7 | 8.11.1 |
| compileSdk / targetSdk | 35 | 36 |

Do not lower one without the others. Pinning `in_app_update` back to 4.2.3
would fix the build but still leave the bundle rejected by Play.

Two warnings are expected and harmless:

- Plugins ask for NDK 27.0.12077973 while the project declares 25.1.8937393.
  No NDK is installed on this Mac and nothing in this app compiles native
  code, so the declared version is never resolved. Raising it would pull a
  ~3GB download for nothing.
- `source/target value 8 is obsolete`. Java 8 compatibility is still what
  Flutter 3.24.5's template sets; raising it is unrelated to shipping.

### 7. Worth doing, not blocking

- **App Tracking Transparency** — done. The UMP consent flow
  (`lib/services/consent_service.dart`) runs before the ads SDK starts, with a
  "Privacy options" entry in Settings, and `_requestTracking()` raises the ATT
  prompt on iOS afterwards. `NSUserTrackingUsageDescription` is in
  `Info.plist` and `PrivacyInfo.xcprivacy` declares `NSPrivacyTracking`.
- **Firebase leaderboard** — was removed only because of Xcode 15.2. Codemagic
  can build it, but re-adding it stops this Mac from building iOS locally.
- **Store listing languages** — the app ships five locales (en/es/hi/id/pt)
  but `store/listing.md` is English-only and its "What's New" predates them.
  Both stores take localised listings.
- `assets/fonts/Syne.ttf` is unused — nothing references it and it is not
  declared in `pubspec.yaml`. Safe to delete.
- Android `applicationId` is `com.arrowsgame.arrows_game` while the iOS bundle
  id is `com.arrowsgame.arrowsGame`. Neither can change after publishing.
