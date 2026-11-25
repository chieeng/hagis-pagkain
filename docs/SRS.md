# Software Requirements Specification (SRS)

**Project:** Hagis Pagkain [Throw Food] — a gamified, offline mobile learning game for mastering the standard d–r forms among Grade 4 learners
**Team:** 2627-sem1-it332-07 (Lobitana, Erag, Manubag, Becera, Cortes) · **Adviser:** Mr. Ralph P. Laviste
**Document version:** 2.0, 25 Nov 2026 (1.x: throw-based core; 2.0: team-approved mechanic redesign — lobby + portals + word-tile path repair, see `docs/superpowers/specs/2026-11-25-portal-tile-redesign-design.md`)
**Source of truth:** `D-R_AlternationLearningGame-Capstone_Proposal` Parts 2–4; the KWF rule as specified in `core/DRRule.gd`.

---

## 1. Introduction

### 1.1 Purpose
This SRS states what the Hagis Pagkain game must do and the constraints it must satisfy, so the team, adviser, and panel share one definition of the Minimum Viable Product (MVP) and so the evaluation (proposal GO5) tests the system that was actually specified.

### 1.2 Scope
An offline Android game, built in Godot 4, with **one user role (the Grade 4 learner)**. The learner practises choosing the KWF **preferred standard form** of five d/r pairs — *din/rin*, *daw/raw*, *dito/rito*, *diyan/riyan*, *doon/roon* — by exploring a 3D world through biome portals and **repairing the broken path: collecting word tiles and placing them into sentence slots** (bridges, gates). There is **no teacher dashboard, no account system, no internet use, and no lesson screen**; the rule is taught inside play. *dati/rati* and other confusable pairs are out of scope.

### 1.3 Definitions
| Term | Meaning |
|---|---|
| Preferred standard form | The d- or r-form the KWF rule selects (KWF, 2014, pp. 35–36). The d-form after a vowel is *not* an error; feedback says "mas wasto", never "mali". |
| Context / stage | The last sound of the word before the blank: `vowel`, `consonant`, `wy` (semivowel), or `exception` (-ra, -ri, -raw, -ray → d-form). **-ro and -re are not exceptions.** |
| First-placement accuracy | % of sentences answered with the preferred form on the first tile placed into their slot. Later placements into the same slot are retries, not answers. (The proposal's "first-throw accuracy", carried over unchanged in meaning.) |
| Biome | One level: Forest (din/rin) → River (daw/raw) → Mountain (dito/rito, diyan/riyan) → Sky (doon/roon + exceptions) → Island (mixed review, placeholder name "Isla"). |
| Item | One validated sentence with a `___` blank, tagged by pair, stage, difficulty, and status (`draft`/`approved`). |
| Accuracy check | ≥ 80% first-throw accuracy over the learner's last 15 sentences in each of the vowel, consonant and w/y stages of a biome. |

### 1.4 References
KWF *Manwal sa Masinop na Pagsulat* (2014, §8.1–8.2, pp. 35–36); *Ortograpiyang Pambansa* (2013, pp. 34–35); MATATAG Filipino CG Grade 4 (panghalip pamatlig Q2, kataga o ingklitik Q3); the capstone proposal Parts 2–4.

---

## 2. Overall description

### 2.1 Product perspective
A standalone, self-contained mobile app. All data (item bank, animal roster, save, play log) lives on the device. Researchers collect the play log manually during sessions; there is no server component, no account system, and no network use of any kind (see the panel review's M2 fix, which aligns the proposal's wording to this).

### 2.2 User class
Grade 4 learners (ages ~9–10), Filipino as L1 or L2, possibly low reading fluency: all learner-facing text is short Filipino at Grade 4 level, large touch targets (≥ 64 px), optional read-aloud. Teachers, advisers and researchers interact with the **content files and logs**, never with an in-app role.

### 2.3 Operating environment
Android 8.0+ phones and tablets, 2 GB RAM, no network. Godot 4.7.2 GL Compatibility renderer, landscape orientation, 1280×720 design resolution stretched to the device.

### 2.4 Constraints
- **C1. KWF correctness.** The rule lives in exactly one component (`DRRule`); every item's answer is validated against it automatically.
- **C2. Framing.** No learner-facing text may call the d-form "mali"/wrong; the target is the preferred standard form.
- **C3. Content governance.** AI- or team-drafted items enter as `status: "draft"`; only the content owner promotes them to `approved` after KWF check and adviser review. Evaluation builds load approved items only.
- **C4. No timers, lives, game-over, public leaderboard, ads, analytics, accounts or internet calls.**
- **C5. Stress-free failure.** A wrong throw costs nothing; the sentence returns later.

---

## 3. Functional requirements

Status column: ✅ built · 🔶 partly built · ⬜ planned (post-MVP unless marked).

### 3.1 Learning inside play (no lesson screen)
| ID | Requirement | Status |
|---|---|---|
| FR-1.1 | On each wild animal's word tag, the deciding last letter (last syllable for exceptions) glows in the colour of the fruit it takes (r-colour for vowel/w/y, d-colour for consonant and exceptions). | ✅ |
| FR-1.2 | The glow fades stepwise with each correct first throw in that stage (gone after 4) and returns in full after a miss in that stage. | ✅ |
| FR-1.3 | The first animal of each new kind (stage) shows a short in-game card — "Bagong uri ng hayop!" — with the word, its glowing letter, the fruit it takes and the rule in one line, while play continues. | ✅ |

### 3.2 Core loop (v2.0: lobby, portals, word-tile path repair)
| ID | Requirement | Status |
|---|---|---|
| FR-2.1 | The game opens in a walkable 3D lobby with one portal per biome; walking into an open portal enters its zone. The learner moves with an on-screen joystick (keyboard supported for development). | ✅ |
| FR-2.2 | A zone is a winding path blocked by stations (broken bridge over water, locked gate), each holding 2 slots (3 from Mountain on) and a caged animal whose rarity comes from the streak. An invisible wall stops the learner until the station is solved. | ✅ |
| FR-2.3 | The word tiles a station needs (each slot's choice set) lie scattered near the path; walking over a tile collects it into the word pouch. In Forest and Island the choices are the pair's two forms; **from River through Sky, three** (plus one form of another pair). | ✅ |
| FR-2.4 | Standing near an unsolved slot shows its sentence with a blank in a banner (read aloud via a "Pakinggan" button when the device has a Filipino TTS voice); the slot's sign carries the word before the blank with its deciding letter glowing. | ✅ |
| FR-2.5 | Tapping a pouch word places it into the active slot. Only the **first placement** in a slot is the answer (`event: "answer"`); every later placement in that slot is a retry, judged against the rule and logged as `event: "retry"`, never as an answer. | ✅ |
| FR-2.6 | Correct placement: the plank or gate bar is built showing the word, with reward effects; coins only on the first-placement answer. | ✅ |
| FR-2.7 | Wrong placement: the tile pops back into the pouch (nothing is lost), the sign's letter blinks, and a hint highlights the deciding letter with a one-line rule; a second wrong on the same sentence shows a worked example (3 steps). | ✅ |
| FR-2.8 | Solving all of a station's slots opens the cage: a celebratory reveal ("NAILIGTAS MO!"), the completed sentences, the animal joins the Animal Index and follows, the wall drops. A missed sentence is re-queued by the session and returns at a later station. | ✅ |
| FR-2.9 | Golden Sky animals speak two-sentence lines with two blanks. | ⬜ (GO4; keep-or-drop decision M9 in the panel review) |

### 3.3 Progression and biomes
| ID | Requirement | Status |
|---|---|---|
| FR-3.1 | Stages inside each biome run vowel → consonant → w/y, then mixed practice that favours the weakest stage. | ✅ |
| FR-3.2 | The Sky biome adds an exception stage that appears only after ≥ 80% first-throw accuracy on the three regular Sky stages. | ✅ |
| FR-3.3 | About 30% of sentences in each biome after Forest come from earlier biomes (spiral review). | ✅ |
| FR-3.4 | The next biome unlocks only when the current biome's Animal Index is complete **and** the accuracy check is met; otherwise extra animals keep appearing in the weaker stage. | ✅ |
| FR-3.5 | The lobby's portals show each biome's progress (animals rescued, sentences answered); any open zone can be replayed; locked portals say what is still needed. | ✅ |
| FR-3.6 | Island opens after Sky, mixes all five pairs and every context including exceptions, teaches no new rule, and offers the pair's own two forms per animal. | ✅ |

### 3.4 Engagement (non-quiz)
| ID | Requirement | Status |
|---|---|---|
| FR-4.1 | Animal Index per biome ([8] animals) with common, rare and golden variants; rare appears after 3 correct first throws in a row, golden after 6 (tunable). | ✅ |
| FR-4.2 | Coin combo multiplier up to ×3 tied to correct-answer streaks; a miss resets it. | ✅ |
| FR-4.3 | Fruit shop (Tindahan): coins buy fruit snacks that raise walking speed; speed never gates learning or unlocks. | ✅ |
| FR-4.4 | Home pen (Kulungan) where collected animals live and idle. | ✅ |
| FR-4.6 | Pen decorating, pen animals earning coins over time, Itlog Pauwi bonus round, recorded voices, detailed models. | ⬜ post-MVP |

### 3.5 Progress and data
| ID | Requirement | Status |
|---|---|---|
| FR-5.1 | My Progress screen: the learner's own first-throw accuracy per pair and per context, and the sentences to review next (recent misses, cleared once answered correctly). | ✅ |
| FR-5.2 | Play log, one JSON line per event with an `event` field: `answer` (one per sentence first placement: biome, item, pair, stage, chosen word, correct, hint level, animal, rarity, streak, coins, time since start) or `retry` (later placements in the same slot). Every line carries a per-run session id and a timestamp. | ✅ |
| FR-5.3 | Save on device: coins, collected animals and variants, per-stage accuracy windows, glow levels, unlocks, shop state, per-pair stats, missed list, answered counts, sessions played. | ✅ |
| FR-5.4 | Researchers collect `user://play_log.jsonl` from each device during sessions (no network export); final log fields are frozen with the research instruments before the pilot. | 🔶 (log built; field freeze pending) |
| FR-5.5 | Nickname/avatar profile, stored only on the device, chosen before the pre-test (no accounts, no personal data). | ⬜ pre-pilot |

### 3.6 Content pipeline
| ID | Requirement | Status |
|---|---|---|
| FR-6.1 | Items load from per-biome JSON files; every item is validated at load and in CI: required fields, blank present, prev_word before the blank, answer equals the DRRule preferred form, stage tag matches prev_word's last sound, status ∈ {draft, approved}. | ✅ |
| FR-6.2 | Evaluation builds exclude drafts (`include_drafts = false`). | ✅ (flag) |
| FR-6.3 | Item bank of ≥ [300] approved items for the evaluation. | ⬜ (prototype ships proposal-derived drafts) |

## 4. Non-functional requirements
| ID | Requirement |
|---|---|
| NFR-1 | Runs at a playable frame rate on Android 8 / 2 GB RAM (GL Compatibility, low-poly); verify on a real low-end device early in Capstone 2. |
| NFR-2 | Fully offline; the APK requests no network or other sensitive permissions. |
| NFR-3 | Learner privacy (RA 10173): no personal data collected; nickname/avatar only, stored on device; logs anonymized before analysis. |
| NFR-4 | All learner-facing text in Grade 4 Filipino, centralized for adviser review (`ui/Strings.gd`, `core/Hints.gd`). |
| NFR-5 | Touch targets ≥ 64 px; landscape; UI readable at 5-inch screens. |
| NFR-6 | Deterministic, unit-tested game logic (no visuals in `core/`); CI runs rule, data and session tests plus a headless autoplay on every PR. |
| NFR-7 | Installable as a single debug APK ≤ ~150 MB via the team's GitHub Actions workflow. |

## 4a. Traceability to the proposal

| Proposal element | SRS requirements |
|---|---|
| GO1 Forest (din/rin) | FR-1.*, FR-2.1–2.8, FR-3.1, FR-3.4, FR-4.1–4.4, FR-6.1 |
| GO2 River (daw/raw + review) | GO1 set + FR-2.3 (three words), FR-3.3 (spiral review) |
| GO3 Mountain (dito/rito, diyan/riyan) | GO2 set over the demonstrative pairs, 3 slots per station |
| GO4 Sky (doon/roon + exceptions) | GO2 set + FR-3.2 (exception gate); FR-2.9 pending the M9 decision in the panel review |
| Island (mixed, no SMART objective) | FR-3.6; its play is logged like the rest (FR-5.2) |
| GO5 Evaluation / RQ1–RQ5 | FR-5.1–5.5, FR-6.2–6.3, NFR-2, NFR-3 |
| "Data tracked" list (Part 3) | FR-5.2 (accuracy per pair/context/biome, retries, hints, time per answer, streaks), FR-5.3 (sessions played, Index completion) |
| Theoretical basis (scaffolding/ZPD) | FR-1.1–1.3, FR-2.7 (glow and hints fade with mastery, return on error) |

## 5. Acceptance criteria for the MVP demo
1. Fresh install opens the lobby; only the Gubat portal is open, and walking into it enters the zone.
2. Gubat is completable by collecting tiles and solving stations: Index 8/8 + accuracy check unlocks the Ilog portal, visibly, back in the lobby.
3. Ilog scatters three word choices per slot; roughly a third of its sentences are din/rin review.
4. Himpapawid hides the exception stage until the regular stages are met, then introduces *Mura din* with the "-ra/-ri/-raw/-ray" card.
5. Isla opens after Himpapawid and mixes all pairs with two choices per slot.
6. My Progress shows per-pair/per-context percentages matching play, and lists missed sentences.
7. Killing and reopening the app restores all progress; `play_log.jsonl` contains exactly one `answer` line per sentence (its first placement) and `retry` lines for later placements, each with a session id; the sessions-played count rises by one per app run.
8. The whole flow works by touch alone on an Android phone (Android 8, 2 GB RAM target device).
