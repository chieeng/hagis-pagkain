# Hagis Pagkain

An offline Android game (Godot 4) that helps Grade 4 learners use the KWF preferred form of
din/rin, daw/raw, dito/rito, diyan/riyan and doon/roon.

**Godot version (everyone must use exactly this):** `4.7.2-stable` (standard, not .NET). If the team changes it, also change `GODOT_VERSION` in `.github/workflows/`.
**Renderer:** GL Compatibility · **Orientation:** landscape, 1280×720

## First-time setup

1. Install the Godot version above (standard build, not .NET).
2. Clone the repo, open Godot, choose **Import**, and select `project.godot`.
3. Press F5. The main menu opens; **Gubat** starts the lesson the first time.
4. Read `AGENTS.md`. It holds the team rules, and your coding assistant reads it too.

## What the prototype does (Forest, din/rin, 3D)

1. **Aralin [Lesson] first** (automatically the first time; replay from the menu or the in-game button):
   look at examples → tap the last letter of words → drag words into the **rin** or **din** basket → play.
2. **3D Forest (Pet Simulator style):** walk with the joystick (or WASD / arrow keys). Wild animals wear a
   word tag (*Ikaw*, *Gutom*, *Masaya*). Pick **rin** or **din** in the hotbar (keys 1 and 2), then **hold
   Ihagis** (or Space): the power meter goes up and down. Let go inside the green band to reach the animal
   with the orange ring. Animals back away if you get too close.
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
3. The next biome unlocks when the Index is full **and** every stage reaches 80% over its last 15 sentences.
   Press **F3** to see per-stage accuracy (team only).

Not built yet: River/Mountain/Sky, audio, the egg bonus round, coins from pen animals over time, My Progress, real art (everything is coloured boxes), and a test on a real phone.

All numbers live in `core/GameConfig.gd`. All learner-facing Filipino text is in `ui/Strings.gd`
and `core/Hints.gd`, ready for review.

## Check it without playing

```
godot --path . -- --autoplay --nosave --shots=C:/some/folder
```

The game goes through the lesson, then walks around the 3D forest by itself, makes 12 throws (including two
misses on the same sentence, to show both hint levels), brings animals to the pen, saves screenshots of each
step and quits. `--nosave` leaves your real save alone.

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

The lead does this once: in Godot, open **Project → Export → Add… → Android** and name the preset exactly
`Android`. Save, then commit `export_presets.cfg`. It holds no passwords.

After that, anyone can get an APK:
- **Actions tab → Android APK → Run workflow**, then download the APK from the run's Artifacts.
- Or push a tag (`git tag v0.1.0 && git push origin v0.1.0`). This also creates a GitHub Release with the APK attached.

These are debug builds for testing. Never commit a release keystore.

## CI

`.github/workflows/ci.yml` runs on every PR. It imports the project (which catches GDScript errors) and
runs `tests/run_tests.gd`. `main` is protected: changes go in only through a PR with one approval and a
passing CI check.
