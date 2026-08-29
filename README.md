# Arrows

Puzzle game for **Android** and **iOS** — clear every arrow without blocking the path.

Arrows span several cells and block along their whole body, so each board is a
woven grid of lines. Tap an arrow with a clear run to the edge and it slides
off; tap a blocked one and it costs a heart.

## Features

- 80 levels (Easy → Expert) + daily challenge (history + streak)
- Multi-cell arrows, 3 hearts per board, progress bar, optional cell grid
- Themes (free + premium pack)
- Leaderboard (local → Firebase when configured)
- Ads (test IDs) + IAP (Remove Ads, Theme Pack)
- Sound, haptics, hints, undo, stars

## Run

```bash
flutter pub get
flutter run
```

## Build

```bash
flutter build apk --release
flutter build ipa
```

## Configure extras

See [EXTRAS.md](EXTRAS.md) for Firebase, AdMob, and IAP production setup.
