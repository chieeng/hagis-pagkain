# Hagis Pagkain — visual style guide

Written with the `game-assets-enhancement` skill (Phase 0 audit + Phase 1 style guide).
Every asset made for this game — generated, modelled or code-drawn — follows this file.
Owner: Alex (look), with the pedagogic colours fixed by Irish/Jian (they are part of the teaching design).

## Style sentence

**Blocky toy-box low-poly:** everything is built from chunky, soft-cornered blocks in flat,
saturated, kid-friendly colours under one warm sun — like a wooden-toy diorama, Pet-Simulator
style. No textures, no gradients-as-style, no photoreal. Original animals and setting only
(the Roblox loop is inspiration; nothing is copied).

## Palette anchors (with jobs)

| Anchor | Value | Job |
|---|---|---|
| R-pink | `#e64980` | **Sacred, pedagogic:** the r-form fruit, r-glowing letters, r word buttons |
| D-orange | `#f08c00` | **Sacred, pedagogic:** the d-form fruit, d-glowing letters, d word buttons (also KWF exceptions) |
| Success green | `#2b8a3e` | Correct reveals, "NAHULI MO!", unlocks |
| Celebration gold | `#ffd43b` | Coins, golden animals, combo |
| Rare teal | `#66d9e8` | Rare animals and their reveal |
| Action orange | `#e8590c` | The one primary action (Ihagis) |
| Cream | `#fff9db` | Cards, banners, panels |
| Ink | `#212529` | Text on cream |

**Semantic colour is sacred.** R-pink and D-orange may never be reused for anything that is
not the r/d distinction — they are the letter-glow scaffold, the core teaching device. There is
no red = danger anywhere: the game has no failure state, and nothing may look like one.

## Lighting rules

1. One sun, upper-left-behind the camera (the existing `DirectionalLight3D`), warm white.
2. Shared warm undertone in the ambient light; no cold grey washes.
3. Aerial perspective sells depth: the farther a silhouette range sits, the lighter, hazier
   and more desaturated it is (lerped toward the sky-horizon colour).
4. Focal hierarchy: backgrounds are calmer than the playfield. A gentle code vignette
   (clear centre → dark edges, ≈0.25 opacity) plus a faint warm radial wash fuse the scene;
   the squint test must always leave the aimed animal and the word buttons as the brightest,
   highest-contrast things on screen.
5. Per-biome palettes live in `world/BiomeWorld.gd` `THEMES` and must keep the playfield more
   saturated than the backdrop.

## Sprite manifest (for the fal.ai generation pass — not yet run)

The skill's Phase 2 generates each element as its own transparent sprite via the fal.ai MCP
(`fal-ai/nano-banana-pro` + `pixelcut/background-removal`). That MCP is not connected yet;
when it is, generate in this order, one object per asset, style-anchored on the player:

1. **Style anchor:** the player character (front, 3/4, back).
2. **Playfield:** 4 fruits (bayabas, mangga, pinya, gintong mangga); 40 animals
   (8 × forest/river/mountain/sky/island), each also needing a golden tint variant
   (rare reuses the common model at 1.2× with teal fx — do not generate separately).
3. **Set pieces, far → near, aerial-desaturated per layer:** mountain ranges (far + near,
   isolated silhouettes, flat bottom edge only), trees (2–3 variants per biome), clouds,
   river water edge, island palms.
4. **Props:** pen fence module, gate, ground scatter (flower, pebble).
5. **UI:** fruit-shop icons, Animal Index silhouettes, biome-select card art (one per biome).

Rules that bind every generation: one sprite = one object (no baked rows or strips); no text
baked into any sprite (code renders all words — the word tags ARE the pedagogy); animals that
animate get frame cycles edited from frame 1; interchangeable variants share one footprint.

## Code polish already applied (skill Phase 3, "cheap, high-impact")

- Two far silhouette ranges around every biome with aerial perspective (far palest, near warmer).
- Warm radial light wash + gentle vignette composited over the 3D scene, under the HUD.
- Warmer ambient light.
- Already in place from earlier work: the world opens in motion (animals wander), idle life,
  landing/catch squash-and-pop, instant input reactions, reveal flash/shake.
