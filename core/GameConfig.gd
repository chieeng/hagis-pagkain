class_name GameConfig
extends RefCounted
## Tunable numbers in one place.
## [proposal] = value stated in the proposal. [prototype] = a guess to confirm in play-tests.

const ACCURACY_WINDOW := 15     ## [proposal] last 15 sentences per stage
const ACCURACY_TARGET := 0.8    ## [proposal] 80% first-throw accuracy per stage
const ANIMALS_PER_BIOME := 8    ## [proposal, to confirm] animals on each Animal Index page
const STAGE_LENGTH := 5         ## [prototype] sentences in a stage before the next stage starts
const REQUEUE_GAP := 3          ## [prototype] a missed sentence comes back after this many other sentences
const COINS_PER_CORRECT := 5    ## [prototype] fallback; see RARITY_COINS

## Streaks of correct first throws [proposal: "rare and golden animals appear after streaks"].
const RARE_STREAK := 3          ## [prototype] streak that brings a rare animal
const GOLDEN_STREAK := 6        ## [prototype] streak that brings a golden animal
const COMBO_STEP := 3           ## [prototype] every 3 in a row adds 1 to the coin multiplier
const COMBO_MAX_MULT := 3       ## [prototype]
const RARITY_COINS := {"common": 5, "rare": 10, "golden": 20}             ## [prototype]
## How close the player can get before the animal backs away. Rarer = shyer = needs a stronger throw.
const RARITY_SHY_DISTANCE := {"common": 3.0, "rare": 6.0, "golden": 8.5}  ## [prototype]

## Learning inside the game (no lesson screen): the deciding last letter on each word tag glows in its
## fruit's colour. The glow fades as the learner gets a stage right, and comes back after a miss.
const HELP_FADE_STEP := 0.25    ## [prototype] each correct first throw lowers that stage's glow by this (1 -> 0 in 4)
const HELP_ON_MISS := 1.0       ## [prototype] the glow level after a miss in that stage
const R_COLOR := "#e64980"      ## [prototype] colour of the r-form fruit and of letters that take r
const D_COLOR := "#f08c00"      ## [prototype] colour of the d-form fruit and of letters that take d

## Zones [redesign 2026-11-25, docs/superpowers/specs]: the path is blocked by stations
## (bridge/gate); each station's slots are sentences, solved by placing collected word tiles.
const STATION_GAP := 24.0       ## [prototype] metres of path between stations
const SLOT_RANGE := 16.0        ## [prototype] how close the player must be to place into a slot (the nearest unsolved one is active)
const TILE_PICKUP := 1.6        ## [prototype] how close the player walks to collect a tile
const SLOTS_FOREST := 2         ## [prototype] slots per station in forest/river
const SLOTS_LATER := 3          ## [prototype] slots per station from mountain on
## Fruit shop tiers [proposal: "coins buy new kinds of food"]. Snacks now make you walk
## faster (speed multiplier), since reach is no longer a mechanic.
const FRUIT_TIERS: Array[Dictionary] = [
	{"id": "bayabas", "name": "Bayabas", "speed": 1.0, "price": 0, "color": "#94d82d"},
	{"id": "mangga", "name": "Mangga", "speed": 1.2, "price": 40, "color": "#fcc419"},
	{"id": "pinya", "name": "Pinya", "speed": 1.4, "price": 100, "color": "#f59f00"},
	{"id": "gintong-mangga", "name": "Gintong Mangga", "speed": 1.7, "price": 250, "color": "#ffe066"},
]

## Stage order inside every biome [proposal]. Sky adds "exception".
const STAGE_ORDER: Array[String] = ["vowel", "consonant", "wy", "exception"]

## Spiral review [proposal]: about 30% of each biome's sentences come from earlier biomes.
const REVIEW_SHARE := 0.3
## From the River biome on, some sentences show three foods, so the learner must pick the
## right word, not only the right letter [proposal, GO2]. Island goes back to the pair's
## own two forms [proposal, Unlocking].
const THREE_CHOICE_BIOMES: Array[String] = ["river", "mountain", "sky"]
## Sky only: the exception stage appears after 80% first-throw accuracy on the three
## regular stages [proposal, GO4].
const GATED_STAGE := "exception"
const GATE_BIOME := "sky"
## How many of the most recent missed sentences My Progress lists for review.
const REVIEW_LIST_MAX := 8
