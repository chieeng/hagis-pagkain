# Hagis Pagkain

An offline Android game (Godot 4) that helps Grade 4 learners use the KWF preferred form of
din/rin, daw/raw, dito/rito, diyan/riyan and doon/roon.

**Godot version (everyone must use exactly this):** `4.7.2-stable` (standard, not .NET). If the team changes it, also change `GODOT_VERSION` in `.github/workflows/`.
**Renderer:** GL Compatibility · **Orientation:** landscape, 1280×720

## First-time setup

1. Install the Godot version above (standard build, not .NET).
2. Clone the repo, open Godot, choose **Import**, and select `project.godot`.
3. Press F5. You should see "Items loaded: …".
4. Read `AGENTS.md`. It holds the team rules, and your coding assistant reads it too.

## Folders

| Folder | What | Owner |
|---|---|---|
| `main/` | Entry scene | Lead |
| `autoload/` | Global singletons: GameState, SaveManager, QuestionBank, AudioManager | see AGENTS.md |
| `core/` | DRRule (the language rule), throwing, food items | Irish / Lead |
| `biomes/` | BiomeTemplate (Lead) and one folder per biome (Loraine) | Lead / Loraine |
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
2. **All biomes:** River, Mountain, Sky built from BiomeTemplate, plus the full question bank.
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
