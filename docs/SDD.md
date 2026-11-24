# Software Design Document (SDD)

**Project:** Hagis Pagkain — d–r alternation learning game (Godot 4.7.2, Android)
**Document version:** 1.1, 25 Nov 2026 (1.0: first draft, 24 Nov; 1.1: event-typed play log with session ids, sessions counter, decision-table additions)
**Companion:** `docs/SRS.md` (what the system must do); this document says **how** it is built. File paths are real paths in this repository.

---

## 1. Design overview

### 1.1 Goals that shaped the design
1. **One source of truth for the KWF rule** (SRS C1): the rule is one static class; everything else asks it.
2. **Testable learning logic**: everything that decides *what the learner practises and whether they were right* lives in visual-free classes under `core/`, unit-tested headlessly in CI. Scenes only display.
3. **One world, five biomes**: a single 3D scene script is parameterized by biome (items, animals, theme), so each biome is a data change, not a code fork.
4. **Cheap phones**: GL Compatibility renderer, box-mesh placeholder art generated in code, shared materials, no textures.

### 1.2 Architecture at a glance
```
          ┌───────────── Scenes (display only) ─────────────┐
          │ main/Main.gd         biome-select screen         │
          │ world/BiomeWorld.gd  one 3D biome (×5 .tscn)     │
          │ world/Animal3D.gd, Player3D, Joystick, PowerMeter│
          │ ui/ MyProgress, Pen, AnimalIndex, FruitShop, …   │
          └───────┬──────────────────────────────┬──────────┘
                  │ calls                        │ signals
          ┌───────▼──────────────┐    ┌──────────▼──────────┐
          │ Autoloads (state)    │    │ core/ (pure logic)  │
          │ GameState  SaveMgr   │───▶│ DRRule  BiomeSession│
          │ QuestionBank AudioMgr│    │ Progress Hints      │
          └───────┬──────────────┘    │ GameConfig          │
                  │ JSON               └─────────────────────┘
          ┌───────▼──────────────┐
          │ data/ items_*.json   │   user:// save.json
          │ data/ animals.json   │   user:// play_log.jsonl
          └──────────────────────┘
```

## 2. Component design

### 2.1 `core/DRRule.gd` — the rule engine (SRS FR-6.1, C1)
Static class. Inputs are plain strings; no state.
- `preferred_form(prev_word, particle)` / `is_preferred(prev_word, chosen)` — the only places the d↔r decision is made.
- `reason(prev_word)` → after_vowel | after_semivowel | after_consonant | kwf_exception; `stage()` maps it to the item stage tag.
- `deciding_length(prev_word)` → how many letters to highlight/glow (1, or 2–3 for -ra/-ri/-raw/-ray).
- Encodes: vowels `aeiou`, semivowels `wy`, exceptions `ra ri raw ray` only (-ro/-re deliberately excluded), pairs din/rin, daw/raw, dito/rito, diyan/riyan, doon/roon (dati/rati excluded).

### 2.2 `core/BiomeSession.gd` — one biome visit (FR-2, FR-3)
Constructed per scene entry: `BiomeSession.new(biome, items, animals, progress, seed, review_items)`. Deterministic under a seed (used by tests).
- **Stage machine:** stages found in the items in `GameConfig.STAGE_ORDER`; `STAGE_LENGTH` sentences each, then `mixed = true` and practice follows `Progress.weakest_stage()`. Island constructs with `mixed = true` (FR-3.6).
- **Exception gate (FR-3.2):** `stage_open(s)` is false for Sky's `exception` until the three regular Sky stages pass `Progress.stage_met`; selection, stage advance and `weakest_stage` all filter through `open_stages()`. `unlock_stages()` excludes the gated stage, so the next-biome check matches the proposal's accuracy-check wording.
- **Sentence pick (`next_sentence`):** requeued misses that are due → else, with probability `REVIEW_SHARE` (0.3), a review item from earlier biomes matching the current stage (FR-3.3) → else an item of the current stage, avoiding repeats and sentences already out in the world.
- **Choices (`_choices_for`, FR-2.6):** the pair's two forms; in `THREE_CHOICE_BIOMES` (river, mountain, sky) plus one random form of another pair; shuffled. Stored on the spawned animal so each animal keeps its own hotbar.
- **`answer(chosen)`** → `{correct, stage, hint_level, coins, streak, multiplier, help}`; updates `Progress` (stage window, pair stats, glow), the requeue, the streak, and pays coins (rarity × combo multiplier). Hint level 1 on first miss of a sentence, 2 (worked example) on its second.
- **`deliver(animal_id, rarity)`** on pen arrival → Index/variant updates + `cleared` (Index complete ∧ accuracy check) which triggers `GameState.unlock_next`.

### 2.3 `core/Progress.gd` — everything earned (FR-5)
Plain data, JSON round-trip (`to_dict`/`from_dict`), owned live by `GameState`, persisted by `SaveManager`.
- Per biome+stage: rolling window of the last 15 first-throw results (`stage_met` = full window ∧ ≥ 80%).
- Glow levels per biome+stage (`help`): −0.25 per correct, reset to 1.0 on a miss (FR-1.2).
- Collections: pen contents, rarity variants, coins, shop state; `biome_cleared` = Index complete ∧ all given stages met (FR-3.4).
- My Progress data (FR-5.1): `pair_stats` (lifetime right/total per pair×stage) and `missed_items` (recent misses, pruned on later success), `answered` per biome for the biome-select cards.

### 2.4 `core/Hints.gd` + `core/GameConfig.gd`
`Hints` builds all feedback bbcode (highlighted word/sentence, one-line rule, 3-step worked example); a test asserts no rule line contains "mali" (C2). `GameConfig` holds every tunable number, each annotated `[proposal]` or `[prototype]`.

### 2.5 Autoloads
- **`GameState`** — biome order/names/scenes (incl. Island), the live `Progress`, `unlock_next` (+ signal).
- **`SaveManager`** — `user://save.json` (whole Progress) and `user://play_log.jsonl` (append-only; one JSON line per `answer` or `short_throw` event, FR-5.2). Generates one `session_id` per app run, stamps it on every line, and increments `Progress.sessions` on launch. `--nosave` disables save and log for autoplay runs.
- **`QuestionBank`** — loads `data/items_*.json` + `data/animals.json`; validates every item at load (FR-6.1) and skips invalid ones loudly; `get_items("island")` aggregates all biomes; `get_review_items(biome, order)` returns earlier biomes' items; `include_drafts` flag for evaluation builds (FR-6.2). Takes no autoload dependencies so tests can compile it standalone.
- **`AudioManager`** — placeholder tones generated in code (whoosh, hit, reveal fanfares, coin, combo) until recorded audio exists.

### 2.6 `world/BiomeWorld.gd` — the one 3D scene (FR-1, FR-2, FR-4)
Each biome `.tscn` is two lines: this script + `biome = "<name>"`.
- **Theming (see `STYLE.md`):** `THEMES[biome]` (sky colours, ground, tree palette, hedge, optional water strip); Sky adds floating clouds, Island sand + sea. Every biome gets two aerial-perspective silhouette ranges (`_build_far_scenery`, far = palest, near = warmer, Mountain tallest) and a warm radial light wash + gentle vignette under the HUD (`_light_grade`). All placeholder art via `world/Blocky.gd` box helpers.
- **HUD:** joystick, dynamic fruit hotbar (rebuilt per aimed animal from its stored choices; word colour = r-form pink / d-form orange, same colours as the letter glow), power meter with green band computed from the aimed animal's distance and the equipped fruit's range, sentence banner (+ TTS via `DisplayServer.tts_*` when a `fil`/`tl` voice exists), Index, shop, combo labels, toasts, hint/catch/intro panels.
- **Throw resolution:** landing point = facing × power × fruit range; any wild animal within `HIT_RADIUS` is hit; short/long throws show "Kulang/Sobrang lakas!" and are not answers (FR-2.5). Correct → celebrate (beam/confetti/flash/shake scaled by rarity), animal follows; pen entry delivers. Wrong → sniff-and-leave + hint panel.
- **Teaching moments:** `_introduce_stage` shows the "Bagong uri ng hayop!" card the first time a stage's animal is aimed at (FR-1.3); `_refresh_help` pushes glow levels to all wild tags after every answer.
- **Autoplay bot** (`--autoplay`): walks, buys, throws (seeded misses for both hint levels), delivers, screenshots (`--shots=DIR`), prints a summary line CI greps. `--biome=<name>` picks the biome.

### 2.7 `main/Main.gd` + `ui/`
- **Biome select (FR-3.5):** one card per biome: open → animals x/8 + sentences answered; locked → what is missing (previous biome's Index or accuracy). Bottom row: Pen, My Progress, coins.
- **`ui/MyProgress.gd` (FR-5.1):** pair × context table from `pair_stats` (— for no data; green at ≥ 80%, orange below) + the missed-sentence list via `QuestionBank.find_item`.
- `AnimalIndex`, `FruitShop`, `Pen`, `UiKit` (shared kid-sized controls), `Strings` (every learner-facing Filipino string, C2/NFR-4).

## 3. Data design

### 3.1 Item (data/items_<biome>.json)
```json
{ "id": "river-w01", "biome": "river", "pair": "daw/raw", "stage": "wy",
  "difficulty": 2, "sentence": "Ikaw ___ ang susunod.", "prev_word": "Ikaw",
  "answer": "raw", "translation": "You are next, they say.",
  "audio": "", "status": "draft", "note": "Proposal GO2 example (KWF-checked)." }
```
Validation (load + CI): required fields; `___` present; `prev_word` occurs before the blank; `answer == DRRule.preferred_form(prev_word, answer)`; `stage == DRRule.stage(prev_word)`; status ∈ {draft, approved}; unique ids.

### 3.2 Save file (user://save.json) — `Progress.to_dict()`
`coins, collected{biome→[ids]}, history{biome→{stage→[bool×≤15]}}, unlocked{biome→bool}, help{biome→{stage→0..1}}, variants{biome→{id→[rarities]}}, owned_fruits, equipped_fruit, pair_stats{pair→{stage→{right,total}}}, missed_items[ids], answered{biome→int}, sessions`.

### 3.3 Play log (user://play_log.jsonl), one line per event
- `event: "answer"` — `{t, sid, biome, item, pair, stage, chosen, correct, hint_level, animal, rarity, streak, coins, ms_since_start, perfect}`.
- `event: "short_throw"` — `{t, sid, biome, item, pair, stage, chosen, short, ms_since_start}`: an aimed throw that reached no animal; logged but **never counted as an answer**, so short-throw rates are reportable (proposal, "Data tracked").
- `sid` is the per-run session id; `Progress.sessions` counts runs. Together they cover the proposal's whole "Data tracked" list. TODO before the pilot: freeze the fields with the research instruments (FR-5.4), and clear each device's old log — lines written by pre-v0.2 builds have no `event` field and must be discarded in analysis.

## 4. Key design decisions and alternatives
| Decision | Why | Alternative rejected |
|---|---|---|
| JSON save + JSONL log, no SQLite | Tiny data, crash-safe append, human-readable for researchers, zero plugin risk | SQLite (proposal suggestion): adds surface, nothing needed queries it on-device |
| No server/sync | Offline-only scope, RA 10173 exposure, logs collected in person | Firebase/Supabase (proposal suggestion, flagged in feasibility review) |
| One `BiomeWorld` + per-biome data | Biomes differ by content/theme only; fixes propagate everywhere | Scene per biome: 5× merge-conflict-prone scenes |
| Device TTS for narration | 0 assets, every item "read aloud" day one | 300+ recorded clips (post-MVP add-on per proposal) |
| Per-animal choice sets | Review sentences from other pairs need their own hotbar | One hotbar per biome: breaks with spiral review |
| Rule checked at data load and in CI | Content errors impossible to ship silently | Trusting item authors |
| Short throws logged, never scored | Proposal tracks them; scoring them would mix aim skill into the d/r measure | Not logging (loses data) or counting as wrong (invalidates the construct) |
| Nickname/avatar profile deferred to pre-pilot | MVP demo needs no identity; the design is a local picker writing one string into the save | Building accounts (violates offline/no-account scope) |

## 5. Testing design
- `tests/run_tests.gd` (headless, exit code): rule cases incl. exceptions and non-exceptions (-ro/-re), highlight/hint builders, every data file item, Progress windows/glow/shop/serialization, session flow (stages, requeue, worked example, streaks/rarity/coins, busy animals, unlock), three-choice/Island behaviour, review mix share, exception gate, pair stats & missed list.
- Autoplay smoke run per biome (`--autoplay --nosave --biome=<b>`) drives the real scene: walking, aiming, both hint levels, shop, delivery, Index; prints a summary line and screenshots.
- CI (`.github/workflows/ci.yml`): import (catches parse errors) → tests → forest autoplay, on every PR. `android.yml` builds the debug APK (preset `Android`, `export_presets.cfg`) on demand or on a `v*` tag.

## 6. Deployment
Debug APK via GitHub Actions (arm64-v8a + armeabi-v7a, min SDK = Godot default ≥ Android 8). Sideloaded for play-tests. Orientation locked to sensor landscape. Evaluation build: set `QuestionBank.include_drafts = false`, bump `version/code`.

## 7. Traceability
SRS FR-1 → §2.6/`Animal3D`; FR-2 → §2.2/§2.6; FR-3 → §2.2/§2.3/§2.7; FR-4 → §2.6/`ui/`; FR-5 → §2.3/§2.5/§2.7; FR-6 → §2.5/§3.1; NFR-6 → §5; NFR-7 → §6. Proposal GO1–GO4 map to the four SMART biomes (data + gate logic above); GO5 consumes the play log (§3.3).
