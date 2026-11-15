# Store listing copy — Arrows

Everything below is ready to paste. Character counts are checked against each
store's limits.

---

## App name / title

**Arrows: Tap Escape Puzzle** — 25 chars (App Store limit 30, Play limit 30).
From 1.1.0. 1.0 shipped as `Arrows: Line Puzzle`, whose words ("line") carry
little search volume; the new name puts "arrows", "tap", "escape" and "puzzle"
in the field Apple weights most. The home-screen label stays `Arrows`
(`CFBundleDisplayName`).

## Subtitle (App Store, 30 chars)

**Brain Teaser Logic Maze Game** — 28

## Keywords (App Store, 100 chars, comma-separated, no spaces)

Never repeat a word already in the name or subtitle — Apple indexes those
already, so a repeat is wasted characters. No competitor or trademarked names.

```
unblock,iq,mind,offline,daily,challenge,board,strategy,relax,solve,line,think,hard,clear,order
```
94 chars

## Short description (Play, 80 chars)

**Tap each arrow out in the right order. 600 logic boards and a daily challenge.** — 78

## Promotional text (App Store, 170 chars — editable any time, no review)

```
600 boards of tap-to-escape logic. One rule: an arrow can only leave if its path is clear. New chapters, a daily challenge, and no internet needed.
```
147 chars

## Full description (Play limit 4000, App Store 4000)

```
Every arrow wants out. Only some of them can leave.

Arrows is a tap-to-escape logic puzzle. Tap an arrow and it slides off the
board — but only if nothing stands in its way. Get the order wrong and it
slams into whatever is blocking it, and you lose a heart.

The catch: an arrow blocks along its whole body, not just its head. A long
arrow lying across the board is a wall. Read the whole line before you commit.

WHAT YOU GET
• 600 boards in 20 packs, from a gentle 3x3 opener to dense 18x18 mazes
• Four difficulties — Easy, Medium, Hard, Expert
• A fresh daily challenge, with a streak to keep alive
• Six colour themes for the board
• Three hearts per board — the ones you have left become your stars
• Undo, hints and an optional cell grid when a board gets tight

BUILT TO PLAY ANYWHERE
No account. No sign-up. No internet needed to play. Your progress stays on
your phone. Pick it up for one board on a train, or lose an hour to an
Expert chapter.

SIMPLE TO LEARN, HARD TO FINISH
The rule takes ten seconds to understand and the last boards will still take
you a while. There is no timer and no pressure — just you, the board, and the
order you choose.
```

## What's New (1.1.0)

```
• 520 new boards in 13 chapters — 600 in all
• The board now sits in the middle of the screen
• Arrows opens in your phone's language: English, Español, Português,
  Bahasa Indonesia or हिन्दी
• Hint packs and an Everything Pack in the Shop
• Try a premium theme free for a day
```

## What's New (first release)

```
First release. 80 boards, daily challenges, six themes, and no internet
required.
```

## Localized listings (App Store)

Each locale has its own name, subtitle and keyword fields. **The US store also
indexes Spanish (Mexico)**, so its keyword field doubles as a second US keyword
field — that is why it carries a few English words. The name stays the English
one everywhere; it is the brand.

| Locale | Subtitle | Keywords |
| --- | --- | --- |
| Spanish (Mexico) | `Rompecabezas de lógica` (22) | `flechas,juego,mente,laberinto,cerebro,reto,diario,ingenio,desbloquear,logica,arrow,brainteaser,iq` (97) |
| Portuguese (Brazil) | `Quebra-cabeça de lógica` (23) | `setas,jogo,mente,labirinto,cérebro,desafio,diário,raciocínio,desbloquear,lógica,offline` (87) |
| Indonesian | `Teka-teki logika & asah otak` (28) | `panah,permainan,otak,labirin,logika,tantangan,harian,asah,offline,strategi,santai` (81) |
| Hindi | `दिमाग़ी पहेली और लॉजिक गेम` (26) | `तीर,पहेली,दिमाग,खेल,लॉजिक,भूलभुलैया,चुनौती,रोज़ाना,ऑफ़लाइन,arrow,puzzle,brain,logic` (83) |

Descriptions for these locales: translate the English one above; the app's own
strings in `lib/l10n/app_*.arb` set the terms (pista / dica / petunjuk / संकेत
for "hint").

## In-app products

| Product id | Type | Price (USD tier) | What it gives |
| --- | --- | --- | --- |
| `arrows_remove_ads` | Non-consumable | $3.99 (was $1.99) | No banners or interstitials, +10 hints once. Rewarded ads stay optional. |
| `arrows_theme_pack` | Non-consumable | $0.99 | Aurora, Noir and Solar |
| `arrows_bundle` | Non-consumable | $4.99 | Everything Pack: both of the above + 30 hints |
| `arrows_hints_15` | Consumable | $0.99 | 15 hints |
| `arrows_hints_60` | Consumable | $2.99 | 60 hints |

Hint counts live in `AppConfig.hintsPerProduct`; keep this table and the store
descriptions in step with it.

## Category

- App Store: Games → Puzzle (secondary: Board)
- Play: Games → Puzzle

## Content rating

Everyone / 3+. No violence, no user-generated content, no chat, no gambling.
Declare **contains ads** and **in-app purchases** on both stores.

## Data safety (Play) / Privacy labels (App Store)

Declare, matching `ios/Runner/PrivacyInfo.xcprivacy` and the privacy policy:

| Item | Answer |
| --- | --- |
| Device or other IDs | Collected, for advertising, **used for tracking** |
| Location | Approximate, derived from IP by the ad SDK |
| Purchases | Handled by the store, not collected by the app |
| App interactions (Play: "App activity") | Collected by Aptabase, **for analytics only**, not linked to identity, not used for tracking, not shared (Aptabase is a service provider). App Store label: add the **Analytics** purpose to Product Interaction, "Not linked to you" |
| Data encrypted in transit | Yes |
| Users can request deletion | Uninstalling removes everything; nothing is held on our servers |

Everything else: not collected. There are no accounts and no backend.

## Screenshots

Generated by `tool/store_screenshots.dart` into `store/screenshots/`:

| Folder | Size | Where it goes |
| --- | --- | --- |
| `ios/` | 1206x2622 | App Store, the "iPhone with Dynamic Island (medium display)" slot — it rejects the older 1290x2796 |
| `ipad/` | 2048x2732 | App Store, the "iPad 13\" display" slot — **required**, the app supports iPad |
| `android/` | 1080x2400 | Play Console phone screenshots |
| `android_tablet/` | 1600x2560 | Play Console tablet screenshots — without them the listing is marked down for large screens |

`iap_review_shop` is not a listing shot; it is the one both stores ask for when
reviewing the in-app purchases. `theme_ocean`, `theme_ember` and `theme_solar`
are not listing shots either — they are the same board under three palettes,
which the themes panel cuts into bands of one screen.

`store/marketing/` mirrors those four folders and holds six panels each.

**Upload `store/marketing/`, not `store/screenshots/`.** The captures are raw
screens; `tool/store_marketing.dart` frames each one with the claim it backs
up, at the same pixel sizes. Run it after regenerating the captures. The first
two carry the listing — they are all most people see before they scroll on.

The panels, in order: the hard board, the blocking rule drawn out, an Expert
board, the level grid, the six themes, and the home screen. Panel two is drawn
live rather than captured — a five-by-five board with a cross where one
arrow's body stops another and a tick where a third has a clear run — and
panel five is one board captured under three palettes and cut into three
bands. Each panel takes its background hue from the palette its capture was
rendered in, so six panels do not read as six near-black rectangles in a
search result. Every capture is measured and windowed to the part of the
screen that is actually drawn; the empty black under a board is not framed.

The window is one size for the whole platform, taken from the board screens
and reused by every panel, so the six phones come out identical and sit in
the same place. A capture with more content than fits — the home screen, the
level list — is slid into that window and loses a little from the bottom
rather than being given a phone of its own size. The headline and sub-line
sit in fixed-height boxes for the same reason: a one-line headline must not
lift that panel's phone up the frame.

App Store Connect states the accepted sizes on the slot itself. The iPhone
slot takes 2556x1179, 1179x2556, 2622x1206 and 1206x2622; the iPad slot takes
2732x2048, 2048x2732, 2752x2064 and 2064x2752.

## App previews

`store/preview/`, regenerated by `tool/app_preview.sh`:

| File | Size | Where it goes |
| --- | --- | --- |
| `app_preview_iphone_6.7.mp4` | 886x1920 | App Store, iPhone 6.5"/6.7" |
| `app_preview_ipad_12.9.mp4` | 1200x1600 | App Store, iPad 12.9" |

Both H.264, 30fps, 23s, with a silent audio track — Apple expects an audio
track even when there is nothing to hear. The version page states the sizes
it takes: 1920x886 or 886x1920 for iPhone, 1600x1200 or 1200x1600 for iPad.
Play Store takes a YouTube link instead, not a file.

The recorder drives the real game, so it reaches `SoundService` the moment it
taps an arrow — and `audioplayers` has no implementation under `flutter
test`. Its `AudioPlayer` is built in a field initialiser, so turning sound
off is not enough; `tool/app_preview.dart` mocks the two audioplayers method
channels and the global event channel, and drops the `MissingPluginException`
raised by the per-player event channel, whose name is a fresh random id that
cannot be mocked ahead of time.

## Header and search results asset

`store/header/`, generated by `tool/store_header.dart`:

| File | Size | Where it goes |
| --- | --- | --- |
| `header_universal.png` | 5244x2950 | App Store Connect → version page → Product Page Information → Header and Search Results |

App Store Connect states the sizes on that page itself: a header asset takes
5244x2950 or 3840x1646, and a search results asset takes 5244x2950, 3840x2560
or 1920x1280. 5244x2950 is the one size both accept, so the same file serves
both slots — what Apple calls a universal asset. The store crops it, so
everything that matters sits inside the centred 3840x1646 rectangle, which is
73% of the width and 56% of the height.

## Required URLs

- Privacy policy — live at https://arrows-privacy.netlify.app
- Support URL — https://arrows-privacy.netlify.app/support/ (source in `store/site/support/`)
- `app-ads.txt` — `store/site/app-ads.txt`, served from the site root so AdMob can
  crawl it. Without it AdMob reports no ad requests. The App Store Marketing
  URL points at the same domain, which is how the crawler finds it.
