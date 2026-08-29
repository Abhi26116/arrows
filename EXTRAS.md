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

One thing: an App Store Connect API key integration named `arrows_asc_key`,
with the App Manager role. The app record must already exist in App Store
Connect. Android needs nothing here — it ships from this Mac.

### 5. Store paperwork

Privacy policy URL (required — the app serves ads and sells IAP), Data Safety
form, privacy nutrition labels, screenshots, description, content rating.

### 6. Worth doing, not blocking

- **Target API level** — Flutter 3.24.5 defaults to `targetSdk 34`. Play
  requires a newer level for new apps; bump via a Flutter upgrade or by setting
  `targetSdk`/`compileSdk` explicitly in `android/app/build.gradle`.
- **App Tracking Transparency** — the UMP consent flow is wired up
  (`lib/services/consent_service.dart`, shown before the ads SDK starts, with a
  "Privacy options" entry in Settings). iOS still needs an ATT prompt on top of
  it for personalised ads; without it iOS ads stay non-personalised and pay
  significantly less. That needs the `app_tracking_transparency` package plus
  an `NSUserTrackingUsageDescription` string.
- **Firebase leaderboard** — was removed only because of Xcode 15.2. Codemagic
  can build it, but re-adding it stops this Mac from building iOS locally.
- Android `applicationId` is `com.arrowsgame.arrows_game` while the iOS bundle
  id is `com.arrowsgame.arrowsGame`. Neither can change after publishing.
