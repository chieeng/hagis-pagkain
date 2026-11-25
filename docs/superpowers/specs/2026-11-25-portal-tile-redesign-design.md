# Redesign: portal lobby + word-tile repair mechanic (replaces throwing)

Approved by Ritchie in chat, 25 Nov 2026, after two in-engine mockup videos
(`spike/PortalSpike.gd`, `spike/BridgeSpike.gd` — throwaway, now superseded by this build).

## Intent

The team played a Roblox hub/portal/quest game and wants Hagis Pagkain to feel like that:
walking, portals, quests, and *solving something* — not throwing. The d–r rule must remain
the only thing the game is about, and every measurement in the proposal must survive.

## The game

- **Lobby (hub).** The game opens in a walkable 3D lobby with five portals: Gubat, Ilog,
  Bundok, Himpapawid, Isla. Open portals glow and show progress (animals rescued, sentences
  answered); locked ones are grey and say what is needed. Walking into an open portal enters
  its zone. Buttons: Kulungan (pen), Aking Pag-unlad, Tindahan.
- **Zone = a journey.** A winding path with obstacle **stations** (broken bridge over water,
  locked gate). Each station has 2 (later 3) **slots**; each slot is one sentence with a
  blank from `BiomeSession` (same stages, spiral review, exception gate as before).
  A trapped animal (rarity from the streak) waits in a cage past the station.
- **Word tiles.** The words a station needs (each slot's choice set: the pair's two forms,
  + one distractor from River on) lie scattered near the path as glowing tiles. Walking
  over one collects it into the word pouch (bottom HUD).
- **Solving.** Stand near a slot: its sentence shows in the banner (read aloud when a
  Filipino TTS voice exists); the sign carries the previous word with the deciding letter
  glowing (same fading scaffold). Tap a pouch word to place it. Right: the plank/bar is
  built *with the word on it*. Wrong: the tile pops out, letter hint (worked example on the
  second wrong on the same sentence), try again — no fail state.
- **Rescue.** All slots solved → the cage opens, the animal joins the Index (deliver) and
  follows. Index + accuracy check unlock the next portal, exactly as before.
- **Economy.** Coins only from correct first placements (× combo multiplier). The shop now
  sells fruit snacks that raise walking speed (range → speed), since reach is no longer a
  mechanic.

## Measurement mapping (nothing in the evaluation changes shape)

- First-throw accuracy → **first-placement accuracy**: only the FIRST tile placed in a slot
  calls `BiomeSession.answer()` (window, pair stats, coins, streak, glow). Retries on the
  same slot are checked against `DRRule` directly and logged as `event: "retry"`.
- Re-queue: a missed sentence is re-queued by the session and reappears at a later station.
- The play log keeps `answer` lines one-per-sentence-first-attempt; `short_throw` events
  are gone (no aiming); `retry` events are new.

## Unchanged

`DRRule`, `BiomeSession` (sentence selection, choices, stages, gate, review, streak),
`Progress`, `Hints`, `QuestionBank`, item banks, animals, save/log, Pen, My Progress,
Animal Index, biome unlock rule, Filipino strings policy ("mas wasto"), STYLE.md colours.

## Removed

`world/BiomeWorld.gd` (throw world), `world/PowerMeter.gd`, `world/SpeedLines.gd`.
The five biome scenes now use `world/ZoneWorld.gd`; the main scene is `main/Hub3D.tscn`.

## Builder calls (mine)

Stations per visit stream endlessly like wild animals did; 2 slots per station in Forest,
3 from Mountain on; bridge and gate dressings alternate; cage opens by sliding its bars;
autoplay bot collects tiles, misses once on purpose (both hint levels), rescues, and prints
the same `AUTOPLAY 3D` summary line CI greps.
