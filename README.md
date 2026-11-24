# Hagis Pagkain

An offline Android game (Godot 4) that helps Grade 4 learners use the KWF preferred form of
din/rin, daw/raw, dito/rito, diyan/riyan and doon/roon.

**Godot version (everyone must use exactly this):** `4.7.2-stable` (standard, not .NET). If the team changes it, also change `GODOT_VERSION` in `.github/workflows/`.
**Renderer:** GL Compatibility · **Orientation:** landscape, 1280×720

## First-time setup

1. Install the Godot version above (standard build, not .NET).
2. Clone the repo, open Godot, choose **Import**, and select `project.godot`.
3. Press F5. The main menu opens; **Gubat** starts the game. There is no lesson screen: the game teaches as you play.
4. Read `AGENTS.md`. It holds the team rules, and your coding assistant reads it too.

## What the prototype does (all five biomes, 3D)

1. **Learning inside the game (no lesson screen).**
   - The **deciding last letter** on each word tag glows in the colour of its fruit: pink for **rin**, orange
     for **din** (*Masay**a***, *Gut**o**m*). The learner sees the pattern before anyone names it.
   - The glow **fades** with each correct first throw in that stage (gone after 4) and **comes back** after a
     miss. A miss also makes the letter jump. Numbers: `HELP_*` in `core/GameConfig.gd`.
   - The first animal of each new kind (vowel, consonant, w/y; exceptions in Sky later) shows a short card:
     *"Bagong uri ng hayop!"* [A new kind of animal!] with the word, its glowing letter, the fruit it takes
     and the rule in one line. The game keeps running.
   - Stages still go vowel → consonant → w/y, then mixed.
2. **3D Forest (Pet Simulator style):** walk with the joystick (or WASD / arrow keys). Wild animals wear a
   word tag (*Ikaw*, *Gutom*, *Masaya*). Pick **rin** or **din** in the hotbar (keys 1 and 2), then **hold
   Ihagis** (or Space): the power meter goes up and down. Let go inside the green band to reach the animal
   with the orange ring. Animals back away if you get too close.
   - The aimed animal's **sentence with a blank** shows in a banner above the word buttons (*Masaya ___ ako.*).
     The blank shows the word in your hand, so picking rin or din fills it and throwing it answers. It is read
     aloud when the device has a Filipino text-to-speech voice (a **Pakinggan** [Listen] button appears).
   - Preferred form: **"NAHULI MO!"** popup with the whole sentence and coins. The animal follows you; walk
     into the **Kulungan** [pen] to add it to the Animal Index.
   - Otherwise: it sniffs and walks off; a hint highlights the deciding last letter (worked example on the
     second miss of the same sentence). The sentence comes back later on another animal. No lives, no timer.
   - **Combo:** correct first throws in a row raise a coin multiplier; 3 in a row brings a **Bihira** [rare]
     animal, 6 a **Ginto** [golden] one. They are shyer, so they need a stronger throw.
   - **Tindahan** [Shop]: spend coins on better fruit that flies farther (Bayabas 10 m → Gintong Mangga 20 m).
   - **Thrill ("juice")**: whoosh + speed lines + the camera chases the fruit with a distance counter and
     slow-motion at the end; a moment of suspense ("?" marks, drum roll); then the reveal: light beam,
     shockwave, confetti, screen flash and shake, sound, "NAHULI MO!" / "BIHIRANG HULI!" / "GINTONG HULI!!"
     popup with a **BAGO!** [NEW!] badge, coins counting up. Rare/golden animals glow with sparkles and a light
     pillar visible across the map. Releasing in the middle of the green band gives **PERPEKTO!** [PERFECT!]
     and bonus coins. Thrill comes from skill and correct answers, never from random luck.
   - Sounds are simple placeholder tones made in code (`autoload/AudioManager.gd`) until real sounds exist.
3. **All five biomes** are playable: Gubat (din/rin) → Ilog (daw/raw) → Bundok (dito/rito, diyan/riyan) →
   Himpapawid (doon/roon + the KWF exceptions) → Isla (mixed review of everything; placeholder name).
   - The game opens on a **biome-select screen** showing progress per biome (animals caught, sentences
     answered); any open biome can be replayed, and locked biomes say what is still needed.
   - **From Ilog on, three fruit words** are offered (e.g., *din, rin, raw*), so the learner must also pick
     the right word; Isla goes back to each animal's own pair.
   - About **30% of each biome's sentences review earlier biomes** (spiral review).
   - In Himpapawid, the **exception stage (-ra, -ri, -raw, -ray → d)** appears only after 80% on the three
     regular stages.
   - The next biome unlocks when the Index is full **and** every regular stage reaches 80% over its last
     15 sentences. Press **F3** to see per-stage accuracy (team only).
4. **Aking Pag-unlad** [My Progress]: the learner's accuracy per pair and per context, plus the sentences
   to review next (recent misses; they leave the list once answered right).

Not built yet: recorded audio (device TTS is used instead), two-blank golden Sky sentences, the egg bonus
round, coins from pen animals over time, pen decorating, real art (everything is coloured boxes), and a
test on a real phone. All new sentence items are `status: "draft"` until Jian and the adviser approve them.
See `docs/SRS.md` and `docs/SDD.md` for the full requirements and design.

All numbers live in `core/GameConfig.gd`. All learner-facing Filipino text is in `ui/Strings.gd`
and `core/Hints.gd`, ready for review.

## Check it without playing

```
godot --path . -- --autoplay --nosave --shots=C:/some/folder
```

The game opens the 3D forest and walks around it by itself, makes throws (including two
misses on the same sentence, to show both hint levels), brings animals to the pen, saves screenshots of each
step and quits. `--nosave` leaves your real save alone. Add `--biome=river` (or mountain/sky/island) to
check another biome.

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
