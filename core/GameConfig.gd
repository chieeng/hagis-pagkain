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

## Throwing: the power meter (0..1) times the fruit's range, in metres.
const HIT_RADIUS := 2.3         ## [prototype] how close the fruit must land to the animal
const METER_PERIOD := 1.6       ## [prototype] seconds for the meter to go up and down once
const PERFECT_WINDOW := 0.4     ## [prototype] "PERPEKTO!" if the landing is within 40% of HIT_RADIUS
const PERFECT_BONUS := 3        ## [prototype] extra coins for a perfect AND correct throw
## Fruit shop tiers [proposal: "coins buy new kinds of food"]. Better fruit flies farther.
const FRUIT_TIERS: Array[Dictionary] = [
	{"id": "bayabas", "name": "Bayabas", "range": 10.0, "price": 0, "color": "#94d82d"},
	{"id": "mangga", "name": "Mangga", "range": 13.0, "price": 40, "color": "#fcc419"},
	{"id": "pinya", "name": "Pinya", "range": 16.0, "price": 100, "color": "#f59f00"},
	{"id": "gintong-mangga", "name": "Gintong Mangga", "range": 20.0, "price": 250, "color": "#ffe066"},
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
