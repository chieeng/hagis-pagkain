class_name GameConfig
extends RefCounted
## Tunable numbers in one place.
## [proposal] = value stated in the proposal. [prototype] = a guess to confirm in play-tests.

const ACCURACY_WINDOW := 15     ## [proposal] last 15 sentences per stage
const ACCURACY_TARGET := 0.8    ## [proposal] 80% first-throw accuracy per stage
const ANIMALS_PER_BIOME := 8    ## [proposal, to confirm] animals on each Animal Index page
const STAGE_LENGTH := 5         ## [prototype] sentences in a stage before the next stage starts
const REQUEUE_GAP := 3          ## [prototype] a missed sentence comes back after this many other sentences
const COINS_PER_CORRECT := 5    ## [prototype]

## Stage order inside every biome [proposal]. Sky adds "exception".
const STAGE_ORDER: Array[String] = ["vowel", "consonant", "wy", "exception"]
