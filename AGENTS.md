# Hagis Pagkain — rules for every coding assistant (Claude Code, Codex) and every teammate

Read this whole file before changing anything.

**Design direction (professor and team feedback Nov 2026; mechanic redesign approved by the team
25 Nov 2026, see `docs/superpowers/specs/2026-11-25-portal-tile-redesign-design.md`):** not quiz-type,
not story-type, and **no lesson screen before play**. The game is a hub-and-portals adventure: the
learner walks a lobby, enters a biome portal, and repairs the broken path (bridges, gates) by
collecting **word tiles** (din, rin, ...) and placing them into sentence slots. The deciding last
letter on each slot's sign glows in its word's colour and fades as they get it right (it comes back
after a miss); the first slot of each new kind shows a short in-game example. Only the FIRST tile
placed in a slot counts as the answer; retries are hints-and-practice. Solving a station frees the
caged animal into the Animal Index. Do not bring back throwing, and do not bring back separate
fill-in-the-blank question screens. `CLAUDE.md` just points here, so there is one set of rules.

## What this is

An offline Android game made in Godot 4 for **Grade 4 learners**. It helps them use the KWF preferred
form of five d/r pairs in Filipino. Biomes and pairs (fixed — do not change without the team lead):

| Biome | Pairs |
|---|---|
| forest | din/rin |
| river | daw/raw |
| mountain | dito/rito, diyan/riyan |
| sky | doon/roon + KWF exceptions |

**dati/rati is excluded.** There is only a student role. No teacher dashboard, no internet, no accounts.

## The language rule (do not "improve" it)

- The previous word ends in a vowel or in **w/y** → r-form (*masaya rin*, *ikaw raw*, *bahay rito*).
- The previous word ends in any other consonant → d-form (*pinsan din*).
- KWF exceptions: the previous word ends in **-ra, -ri, -raw, -ray** → d-form (*mura din*).
- **-ro and -re are NOT exceptions.** Some websites and secondary sources say they are. Ignore them.
- Source: KWF *Manwal sa Masinop na Pagsulat* (2014), §8.1–8.2, pp. 35–36.
- KWF says the d-form after a vowel is **not an error**. All feedback text says "the preferred form
  here is …". Never say "wrong", "mali" or "incorrect Filipino".
- The rule lives in **one place only: `core/DRRule.gd`.** Never copy or rewrite it in another file.
  Call `DRRule.preferred_form()` / `DRRule.is_preferred()` instead.

## Content rules

- **Never invent Filipino sentences and put them in `data/`.** An assistant may draft items only when a
  teammate asks, and they must have `"status": "draft"`. Only Jian changes an item to `"approved"`, after
  a KWF check and adviser review.
- Item format: see `data/README.md`. The tests check that every answer matches `DRRule`.
- Keep vocabulary at a Grade 4 level: short sentences, everyday words.

## Who owns what

Edit only files you own. To change someone else's file, open an issue or ask them. Owners are
also listed in `.github/CODEOWNERS`, so GitHub asks them to review.

| Member | Area | Files |
|---|---|---|
| Lead | Integration, core gameplay, build | `project.godot`, `main/`, `autoload/GameState.gd`, `world/BiomeWorld.gd`, `world/Player3D.gd`, `world/Animal3D.gd` (behaviour), `world/Joystick.gd`, `.github/` |
| Loraine | Biome levels (assists Lead) | `biomes/forest/`, `biomes/river/`, `biomes/mountain/`, `biomes/sky/` (each a scene using `world/BiomeWorld.gd`) |
| Irish | Systems | `core/DRRule.gd`, `core/BiomeSession.gd`, `core/Progress.gd`, `core/Hints.gd` (logic), `core/GameConfig.gd`, `autoload/SaveManager.gd`, `tests/` |
| Jian | Content + QA/research | `data/`, `autoload/QuestionBank.gd`, `docs/testing/`, Filipino wording in `ui/Strings.gd` and `core/Hints.gd` |
| Alex | UI, art, audio | `ui/` (except Strings wording), `world/Blocky.gd` and model look, `assets/`, `autoload/AudioManager.gd` |

Game logic stays in `core/BiomeSession.gd` and `core/Progress.gd`, which have no visuals and are unit-tested.
Scenes only display it. All tunable numbers go in `core/GameConfig.gd`.

**Scenes (`.tscn`) cause the worst merge conflicts.** Never edit a scene you do not own, even "just a
small fix". Make your own small scene and instance it.

## How to work

1. Pick or create a GitHub issue. Keep it small (one PR, ideally under ~300 changed lines).
2. Branch from `main`: `feat/<short-name>`, `fix/<short-name>` or `content/<short-name>`.
3. Run the tests before every PR (see below). If you change `core/DRRule.gd`, add a test case.
4. Open a PR using the template. A **human** reviewer must approve. AI review alone is not enough.
5. The lead merges. Nobody pushes straight to `main`.

## Tests

```
godot --headless -s tests/run_tests.gd
```

Open the project in the Godot editor once after cloning, so Godot builds its class cache. Exit code 0
means everything passed.

## Godot conventions

- Everyone uses the **same Godot 4.x version**, listed in `README.md`.
- Renderer: GL Compatibility (it runs on cheap Android phones).
- GDScript: tabs, `snake_case` for functions and variables, `PascalCase` for classes and scene files, and
  static types where reasonable.
- Talk between scenes with **signals**, not by reaching into another scene's child nodes.
- Shared state only goes through autoloads: `GameState`, `SaveManager`, `QuestionBank`, `AudioManager`.
- Commit `.import` and `.uid` files. Never commit `.godot/`.
- Keep images and audio small (PNG/OGG, under ~1 MB each). This is a phone game.

## Assistants: do not

- Do not add internet calls, analytics, ads, accounts or a teacher dashboard.
- Do not add dati/rati or any pair beyond the five above.
- Do not rename the autoloads, or the signals/functions in `world/BiomeWorld.gd`, `world/Animal3D.gd` and
  `core/BiomeSession.gd`, without the lead. Other people's code depends on them.
- Do not mass-reformat files you were not asked to touch.
