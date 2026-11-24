# Software Requirements Specification (SRS)

**Project:** Hagis Pagkain [Throw Food] — a gamified, offline mobile learning game for mastering the standard d–r forms among Grade 4 learners
**Team:** 2627-sem1-it332-07 (Lobitana, Erag, Manubag, Becera, Cortes) · **Adviser:** Mr. Ralph P. Laviste
**Document version:** 1.0 (draft for team review), 24 Nov 2026
**Source of truth:** `D-R_AlternationLearningGame-Capstone_Proposal` Parts 2–4; the KWF rule as specified in `core/DRRule.gd`.

---

## 1. Introduction

### 1.1 Purpose
This SRS states what the Hagis Pagkain game must do and the constraints it must satisfy, so the team, adviser, and panel share one definition of the Minimum Viable Product (MVP) and so the evaluation (proposal GO5) tests the system that was actually specified.

### 1.2 Scope
An offline Android game, built in Godot 4, with **one user role (the Grade 4 learner)**. The learner practises choosing the KWF **preferred standard form** of five d/r pairs — *din/rin*, *daw/raw*, *dito/rito*, *diyan/riyan*, *doon/roon* — by throwing labelled food to animals in a 3D world. There is **no teacher dashboard, no account system, no internet use, and no lesson screen**; the rule is taught inside play. *dati/rati* and other confusable pairs are out of scope.

### 1.3 Definitions
| Term | Meaning |
|---|---|
| Preferred standard form | The d- or r-form the KWF rule selects (KWF, 2014, pp. 35–36). The d-form after a vowel is *not* an error; feedback says "mas wasto", never "mali". |
| Context / stage | The last sound of the word before the blank: `vowel`, `consonant`, `wy` (semivowel), or `exception` (-ra, -ri, -raw, -ray → d-form). **-ro and -re are not exceptions.** |
| First-throw accuracy | % of sentences answered with the preferred form on the first throw that reaches the animal. Short throws are not answers. |
| Biome | One level: Forest (din/rin) → River (daw/raw) → Mountain (dito/rito, diyan/riyan) → Sky (doon/roon + exceptions) → Island (mixed review, placeholder name "Isla"). |
| Item | One validated sentence with a `___` blank, tagged by pair, stage, difficulty, and status (`draft`/`approved`). |
| Accuracy check | ≥ 80% first-throw accuracy over the learner's last 15 sentences in each of the vowel, consonant and w/y stages of a biome. |

### 1.4 References
KWF *Manwal sa Masinop na Pagsulat* (2014, §8.1–8.2, pp. 35–36); *Ortograpiyang Pambansa* (2013, pp. 34–35); MATATAG Filipino CG Grade 4 (panghalip pamatlig Q2, kataga o ingklitik Q3); the capstone proposal Parts 2–4.

---

## 2. Overall description

### 2.1 Product perspective
A standalone, self-contained mobile app. All data (item bank, animal roster, save, play log) lives on the device. Researchers collect the play log manually during sessions; there is no server component.

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

### 3.2 Core loop
| ID | Requirement | Status |
|---|---|---|
| FR-2.1 | The learner walks a character through a 3D biome with an on-screen joystick (keyboard supported for development). | ✅ |
| FR-2.2 | Wild animals wander, wear the word tag of the word before the blank, and back away when approached; rarer animals keep a greater distance. | ✅ |
| FR-2.3 | When the learner aims at an animal, its sentence with a blank is shown in a banner; the blank previews the word currently in hand. When a Filipino TTS voice exists on the device, a "Pakinggan" button reads it aloud. | ✅ |
| FR-2.4 | The learner answers by picking a fruit word and holding the throw button: a power meter cycles, and releasing inside the green band makes the fruit reach the animal. | ✅ |
| FR-2.5 | A throw that falls short or misses reaches no animal, counts as **no answer**, and is logged as a short throw. | ✅ |
| FR-2.6 | In Forest and Island, two fruit words (the pair's d- and r-forms) are offered; **from River through Sky, three** (plus one form of another pair), so the learner must also pick the right word. | ✅ |
| FR-2.7 | Correct first throw: celebratory reveal ("NAHULI MO!"), the completed sentence, immediate coins; the animal follows the learner and joins the Animal Index when it reaches the pen. | ✅ |
| FR-2.8 | Wrong throw: the animal sniffs and leaves; a visual hint highlights the deciding letter with a one-line rule; the sentence re-queues after a few other sentences. | ✅ |
| FR-2.9 | A second wrong throw on the same sentence shows a worked example (3 steps). | ✅ |
| FR-2.10 | Golden Sky animals speak two-sentence lines with two blanks. | ⬜ (GO4; decide per feasibility review) |

### 3.3 Progression and biomes
| ID | Requirement | Status |
|---|---|---|
| FR-3.1 | Stages inside each biome run vowel → consonant → w/y, then mixed practice that favours the weakest stage. | ✅ |
| FR-3.2 | The Sky biome adds an exception stage that appears only after ≥ 80% first-throw accuracy on the three regular Sky stages. | ✅ |
| FR-3.3 | About 30% of sentences in each biome after Forest come from earlier biomes (spiral review). | ✅ |
| FR-3.4 | The next biome unlocks only when the current biome's Animal Index is complete **and** the accuracy check is met; otherwise extra animals keep appearing in the weaker stage. | ✅ |
| FR-3.5 | The game opens on a biome-select screen showing each biome's progress (animals caught, sentences answered); any open biome can be replayed; locked biomes say what is still needed. | ✅ |
| FR-3.6 | Island opens after Sky, mixes all five pairs and every context including exceptions, teaches no new rule, and offers the pair's own two forms per animal. | ✅ |

### 3.4 Engagement (non-quiz)
| ID | Requirement | Status |
|---|---|---|
| FR-4.1 | Animal Index per biome ([8] animals) with common, rare and golden variants; rare appears after 3 correct first throws in a row, golden after 6 (tunable). | ✅ |
| FR-4.2 | Coin combo multiplier up to ×3 tied to correct-answer streaks; a miss resets it. | ✅ |
| FR-4.3 | Fruit shop (Tindahan): coins buy fruit with longer throw range; range never gates biome unlocks. | ✅ |
| FR-4.4 | Home pen (Kulungan) where collected animals live and idle. | ✅ |
| FR-4.5 | Perfect-release bonus ("PERPEKTO!") for releasing mid-band. | ✅ |
| FR-4.6 | Pen decorating, pen animals earning coins over time, Itlog Pauwi bonus round, recorded voices, detailed models. | ⬜ post-MVP |

### 3.5 Progress and data
| ID | Requirement | Status |
|---|---|---|
| FR-5.1 | My Progress screen: the learner's own first-throw accuracy per pair and per context, and the sentences to review next (recent misses, cleared once answered correctly). | ✅ |
| FR-5.2 | Play log (one line per answering throw): biome, item, pair, stage, chosen word, correct, hint level, animal, rarity, streak, coins, time since start, perfect flag, timestamp. | ✅ |
| FR-5.3 | Save on device: coins, collected animals and variants, per-stage accuracy windows, glow levels, unlocks, shop state, per-pair stats, missed list, answered counts. | ✅ |
| FR-5.4 | Session id in the log and a researcher export path agreed with the instruments. | 🔶 (fields exist; session id TODO) |

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

## 5. Acceptance criteria for the MVP demo
1. Fresh install opens the biome-select screen; only Forest is open.
2. Forest is completable: Index 8/8 + accuracy check unlocks River; the unlock is visible on the biome-select screen.
3. River offers three fruit words; roughly a third of its sentences are din/rin review.
4. Sky hides the exception stage until the regular stages are met, then introduces *Mura din* with the "-ra/-ri/-raw/-ray" card.
5. Island opens after Sky and mixes all pairs with two choices per animal.
6. My Progress shows per-pair/per-context percentages matching play, and lists missed sentences.
7. Killing and reopening the app restores all progress; `play_log.jsonl` contains one line per answering throw.
8. The whole flow works by touch alone on an Android phone.
