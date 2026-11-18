# Growth kit — Arrows, from 16 Nov 2026

Ready-to-paste copy for the pieces of the growth plan that go through a store
console. Nothing here has been submitted; each console step below is the
user's to approve. Character counts are checked by script against each limit.

Goal: ₹1,00,000/month by about 15 Feb 2027. Checkpoints 15 Dec, 15 Jan, 15 Feb.
Baseline (ASC, launch → 13 Nov): 397 impressions, 9 page views, 4 downloads.

---

## 1. Play — "Apply for production" answers

**When:** the dashboard on 16 Nov said "12 testers have currently been opted in
for 6 days continuously", so day 14 lands on **about 24 Nov 2026**. The button
stays grey until then.

**Risk:** exactly 12 testers are opted in, so there is no margin. If one leaves,
the count drops to 11 and the 14 days start again. Adding 3–5 more testers now
costs nothing and protects the run (the user decides; see
`arrows-closed-testing-hands-off`).

**Engagement matters:** Google turns applications down for "insufficient tester
engagement". Over the remaining days, ask testers to open the app every day or
two and to leave a line of private feedback on the Play listing
("Testing feedback" in Play Console collects it).

Each text box takes 300 characters. Lines marked **[confirm]** are templates: they describe what a test like
this usually looks like, not what these testers did. Replace them with what
actually happened before pasting — Google can check engagement.

### Step 1 — About your closed test

**How did you recruit users?** [confirm]
```
Friends, family and fellow app developers from my own contact list. I sent each of them the Play opt-in link by email and WhatsApp, and kept an email list of testers in Play Console. I also tested on my own Android phone with a licence-test account.
```

**How easy was it to recruit testers?** — pick one; "Difficult" is the honest
default for a solo developer. [confirm]

**Describe the engagement you received** [confirm — check Play Console →
Statistics and Testing feedback before pasting]
```
Testers played [which levels / how far], tried [daily challenge, hints, undo, themes — whichever they used], and played [how often, e.g. a few short sessions a week]. [Any feature nobody tried, and why.]
```

**Summary of feedback and how it was collected** [confirm]
```
Feedback came by [WhatsApp / email / Play private feedback]. Main points: [what testers said]. [What you changed because of it, e.g. the board now sits in the centre of the screen and the app opens in the phone's language.]
```

### Step 2 — About your game

**Intended audience**
```
Casual puzzle players aged 13 and up who like short logic games they can play offline, one board at a time, on a commute or a break.
```

**How does the game provide value?**
```
A tap-to-escape logic puzzle: tap an arrow and it slides out only if its path is clear. 600 boards from 3x3 to 18x18, a daily challenge with streaks, hints and undo. No account, no internet needed, and progress stays on the phone.
```

**Expected installs in the first year:** 0–10K (honest for an organic launch).

### Step 3 — Production readiness

**What changes did you make based on the closed test?**
```
Version 1.1.0 centres the board on every screen size, opens in the phone's language (English, Hindi, Indonesian, Portuguese, Spanish), adds 520 levels for 600 in all, and adds hint packs so players who get stuck can keep going.
```

**How did you decide the game is ready?**
```
52 automated tests pass, release builds were played on a real Android 12 phone, ads were checked with test ads and purchases with a licence-test account, and the same game has been live on the iOS App Store since 6 Nov 2026.
```

---

## 2. App Store — featuring nomination (1.1.0) — SUBMITTED 16 Nov 2026

Submitted by Claude in App Store Connect with the user's OK. Nomination ID
`e4ad8665-513b-4070-855c-85014c4846a9`; it is under Distribution → Featuring →
Nominations → Submitted. Apple's editors write back only if the app is picked.
App Store Connect warned that 3 weeks' notice is recommended; this went in 2
days before the expected release.

What was sent:
- **Name:** Arrows 1.1.0 — 600 boards and five languages
- **Type:** App Enhancements · **Publish date:** 18 Nov 2026
- **Related apps:** Arrows only · **Platforms:** iPhone, iPad · **Countries:** all
- **Languages:** English (U.S.), Hindi, Indonesian, Portuguese (Brazil), Spanish (Mexico)
- **"Intend to submit a new in-app event":** ticked (section 3 below)
- **Description:**
```
Arrows is a calm tap-to-escape logic puzzle: an arrow can only leave the board if its whole path is clear. Version 1.1.0 grows the game from 80 to 600 boards in thirteen new chapters, up to dense 18x18 mazes. It now opens in the player's own language (English, Hindi, Indonesian, Brazilian Portuguese and Mexican Spanish), and the App Store listing is localized in all five. Everything plays offline with no account and no sign-up, and progress stays on the device. The board is now centred on every iPhone and iPad screen, and a daily challenge with streaks gives players a reason to come back each day. New hint packs help players who get stuck keep going. Arrows is made by Tiny Genius Hub, an independent developer.
```
- **Helpful details:**
```
Tiny Genius Hub is an independent developer that also publishes Memory Match, Sudoku Pulse and TinyGenius Hub: Phonics & Math on the App Store. Arrows is built to be played anywhere: no account, no sign-up and no internet needed. With 1.1.0 it speaks Hindi, Indonesian, Brazilian Portuguese and Mexican Spanish as well as English, so players in India, Indonesia and Latin America can play in their own language. We plan an In-App Event for the 600-board launch once the update is live.
```

For the next update (for example the December winter pack), nominate at least
3 weeks before release.

---

## 3. App Store — In-App Event "520 New Boards" (after 1.1.0 is live)

ASC → Distribution → In-App Events → Create In-App Event. Needs an approved
version, so create it right after 1.1.0 goes live. Events go through review
(about a day).

- **Reference name:** `1.1.0 — 600 boards launch`
- **Badge:** Major Update
- **Purpose:** Attract new users
- **Priority:** High
- **Event start:** the day after 1.1.0 is live · **End:** 30 days later (limit 31)
- **Publish on product page:** as soon as approved (up to 14 days before start)
- **Countries:** all
- **Deep link:** none (opens the app)
- **Images:** `store/events/event_card_1920x1080.png` (event card, 16:9) and
  `store/events/event_details_1080x1920.png` (details page, 9:16). Neither has
  text in it, because Apple lays the event name over the image.

| Locale | Event name (30) | Short description (50) | Long description (120) |
| --- | --- | --- | --- |
| English (U.S.) | 520 New Boards Are Here | 13 new chapters, from Drift to Infinity. | Arrows grows to 600 boards. Thirteen new chapters climb from easy Drift to dense 18x18 Infinity. How far can you get? |
| Hindi | 520 नए लेवल आ गए | Drift से Infinity तक, 13 नए चैप्टर। | Arrows में अब 600 लेवल हैं। 13 नए चैप्टर आसान Drift से कठिन 18x18 Infinity तक जाते हैं। आप कहाँ तक पहुँचेंगे? |
| Indonesian | 520 Level Baru Telah Hadir | 13 bab baru, dari Drift hingga Infinity. | Arrows kini punya 600 level. 13 bab baru dari Drift yang santai hingga Infinity 18x18 yang padat. Sejauh mana kamu bisa? |
| Portuguese (Brazil) | 520 Níveis Novos Chegaram | 13 capítulos novos, de Drift a Infinity. | Arrows agora tem 600 níveis. 13 capítulos novos vão do tranquilo Drift ao denso Infinity 18x18. Até onde você chega? |
| Spanish (Mexico) | 520 Niveles Nuevos | 13 capítulos nuevos, de Drift a Infinity. | Arrows ya tiene 600 niveles. 13 capítulos nuevos van del tranquilo Drift al denso Infinity 18x18. ¿Hasta dónde llegas? |

Chapter names (Drift, Infinity) stay in English in every locale because the app
shows them in English. The non-English rows say "levels" because that is the
word the app itself uses in those languages.

**Next event idea (needs an app update, not just copy):** a December "Winter
pack" — a short run of new boards plus a winter theme, shipped in a 1.2 build
and announced as a *Special Event*. Apple turns down events for content that is
always there, so the daily challenge alone is not enough for an event.

---

## 4. YouTube Shorts / Instagram Reels

Clips live in `store/shorts/` (1080x1920, H.264, silent audio track — add a
trending sound inside the app when posting). Each one plays a real board from
the shipping game, start to finish.

Post 3–4 a week rather than all at once. Same clip on both platforms is fine.
Pin a comment with the store link. Android link goes in once Play production is
live.

**Links**
- App Store: `https://apps.apple.com/app/id6806600440`
- Google Play (after production): `https://play.google.com/store/apps/details?id=com.arrowsgame.arrows_game`

**Clips and captions** (Shorts title ≤ 100 chars; the first line is what shows).
Re-record or add clips with `./tool/shorts.sh <level> <name> "<caption>" ["<end caption>"] [hold-frames]`.

| File | Board | On-screen caption | Post title / first line | Hashtags |
| --- | --- | --- | --- | --- |
| `challenge_level30.mp4` | 11x11, 30 arrows, 3 s pause first · 18 s | Pause. Which arrows can escape first? | Pause it. Which arrows can escape first? 🤔 #shorts | #puzzle #brainteaser #logicpuzzle #puzzlegame #iqtest |
| `hindi_level56.mp4` | 15x15, 83 arrows · 28 s | क्या आप सारे तीर सही क्रम में निकाल सकते हैं? | क्या आप सारे तीर सही क्रम में निकाल सकते हैं? 🧠 #shorts | #पहेली #dimagikhel #puzzle #brainteaser #indiangamer |
| `satisfying_level200.mp4` | 18x18, 110 arrows · 29 s | Clearing an 18x18 board, one arrow at a time | So satisfying… every arrow out in the right order ✅ | #satisfying #oddlysatisfying #puzzle #mobilegames |
| `level600.mp4` | 18x18, the last board · 29 s | Level 600. The last board. | Level 600. The last board. Can you get this far? | #puzzle #hardpuzzle #logicgame #puzzlegame #shorts |

Big boards play at up to 2x so every clip lands near 28 seconds. Every clip
ends on the game's own "Cleared" card with "Arrows: Tap Escape
Puzzle / Free on the App Store" (Hindi clip: "Arrows: तीर पहेली / App Store पर
मुफ़्त"). Post `level600.mp4` and `satisfying_level200.mp4` only after 1.1.0 is
live — the App Store version before it has 80 levels.

**Description (all clips)**
```
Arrows: Tap Escape Puzzle — tap an arrow, and it escapes only if its path is clear. 600 boards, daily challenge, plays offline.
iPhone: https://apps.apple.com/app/id6806600440
```
