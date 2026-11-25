# Hagis Pagkain

An offline Android game (Godot 4) that helps Grade 4 learners use the KWF preferred form of
din/rin, daw/raw, dito/rito, diyan/riyan and doon/roon.

**Godot version (everyone must use exactly this):** `4.7.2-stable` (standard, not .NET). If the team changes it, also change `GODOT_VERSION` in `.github/workflows/`.
**Renderer:** GL Compatibility · **Orientation:** landscape, 1280×720

## First-time setup

1. Install the Godot version above (standard build, not .NET).
2. Clone the repo, open Godot, choose **Import**, and select `project.godot`.
3. Press F5. The lobby opens; walk into the **Gubat** portal to play. There is no lesson screen: the game teaches as you play.
4. Read `AGENTS.md`. It holds the team rules, and your coding assistant reads it too.

## What the prototype does (lobby + five biome zones, 3D)

1. **Lobby with portals.** The game opens in a walkable 3D hub with one glowing portal per biome:
   Gubat (din/rin) -> Ilog (daw/raw) -> Bundok (dito/rito, diyan/riyan) -> Himpapawid (doon/roon +
   the KWF exceptions) -> Isla (mixed review; placeholder name). Open portals show progress (animals
   rescued, sentences answered); locked ones say what is still needed. Walk into a portal to enter.
2. **Zones are journeys.** A winding path is blocked by stations: a broken bridge over water, a
   locked gate. Word tiles (din, rin, ...) lie scattered near the path; walk over one to collect it
   into the word pouch.
3. **Learning inside the game (no lesson screen).**
   - Each station slot is one sentence with a blank, shown in a banner (and read aloud when the
     device has a Filipino TTS voice, with a **Pakinggan** button). The slot's sign carries the word
     before the blank with its **deciding last letter glowing** in the colour of the word it takes
     (pink r-form, orange d-form). The glow fades with correct first placements and returns after a
     miss. The first slot of each new kind shows a one-line **"Bagong uri ng hayop!"** card in play.
   - Tap a pouch word to place it. Right: the plank or gate bar is built **with the word on it**.
     Wrong: the tile pops back to the pouch, the letter hint shows (a worked example on the second
     wrong of the same sentence). No lives, no timer, no fail state.
   - Only the **first placement** in a slot counts as the answer (first-placement accuracy, logged);
     retries are practice and are logged as `retry` events.
4. **Rescue and collect.** Solving every slot of a station opens the cage past it: the animal joins
   the Animal Index, follows you, and the invisible wall drops. Streaks of correct first placements
   bring **rare (3) and golden (6)** animals and raise the coin multiplier (x3 max). Coins buy fruit
   snacks in the **Tindahan** that make you walk faster. Spiral review mixes ~30% earlier-biome
   sentences in; Himpapawid's exception stage opens after 80% on its regular stages; Isla mixes
   everything. The next portal unlocks when the Index is full **and** every regular stage reaches
   80% over its last 15 sentences. Press **F3** for per-stage accuracy (team only).
5. **Aking Pag-unlad** [My Progress]: accuracy per pair and per context, plus the sentences to
   review next.

Not built yet: recorded audio (device TTS is used instead), two-blank golden Sky sentences, pen
decorating, coins from pen animals over time, real art (everything is coloured boxes), and a test on
a real phone. All new sentence items are `status: "draft"` until Jian and the adviser approve them.
See `docs/SRS.md`, `docs/SDD.md` and `docs/superpowers/specs/2026-11-25-portal-tile-redesign-design.md`.

All numbers live in `core/GameConfig.gd`. All learner-facing Filipino text is in `ui/Strings.gd`
and `core/Hints.gd`, ready for review.

## Check it without playing

```
godot --path . -- --autoplay --nosave --shots=C:/some/folder
```

The game walks the lobby into the Gubat portal by itself, collects tiles, solves stations (missing
twice on one sentence to show both hint levels), rescues animals, buys from the shop, saves
screenshots of each step and quits. `--nosave` leaves your real save alone. To check another zone,
run its scene directly: `godot --path . res://biomes/river/River3D.tscn -- --autoplay --nosave`.

## Folders

| Folder | What | Owner |
|---|---|---|
| `main/` | Entry scene | Lead |
| `autoload/` | Global singletons: GameState, SaveManager, QuestionBank, AudioManager | see AGENTS.md |
| `core/` | Game logic with no visuals: DRRule, BiomeSession, Progress, Hints, GameConfig | Irish |
| `world/` | 3D world: BiomeWorld, Player3D, Animal3D, Joystick, Blocky look | Lead / Alex |
| `biomes/` | One folder per biome scene, e.g. `forest/Forest3D.tscn` (Loraine) | Loraine |
| `ui/` | Menus, feedback popup, results | Alex |
| `assets/` | Art and sound | Alex |
| `data/` | Question items (JSON) | Jian |
| `tests/` | Test runner | Irish |

## Run the tests

```
godot --headless -s tests/run_tests.gd
```

## Sprints

1. **Vertical slice:** Forest (din/rin) playable on an Android phone.
2. **All biomes:** River, Mountain, Sky built from world/BiomeWorld.gd, plus the full question bank.
3. **Systems:** save, badges and levels, adaptivity, play log.
4. **Polish and pilot:** usability fixes, a small Grade 4 trial, then a frozen build.

## Android export

`export_presets.cfg` with the `Android` preset is already committed (it holds no passwords).
Anyone can get an APK:
- **Actions tab → Android APK → Run workflow**, then download the APK from the run's Artifacts.
- Or push a tag (`git tag v0.1.0 && git push origin v0.1.0`). This also creates a GitHub Release with the APK attached.

These are debug builds for testing. Never commit a release keystore.

## CI

`.github/workflows/ci.yml` runs on every PR. It imports the project (which catches GDScript errors) and
runs `tests/run_tests.gd`. `main` is protected: changes go in only through a PR with one approval and a
passing CI check.
