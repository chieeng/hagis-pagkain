class_name Strings
extends RefCounted
## Every Filipino text the learner sees (except hint rules in core/Hints.gd), in one place
## so Jian and the adviser can review the wording. English in brackets is for the team only.
## Rule: say "mas wasto" [more correct]; never "mali" [wrong].

const TITLE := "Hagis Pagkain"
const SUBTITLE := "Ihagis ang tamang pagkain sa mga hayop!"   # [Throw the right food to the animals!]
const PLAY := "Maglaro"                                       # [Play]
const PEN := "Kulungan"                                       # [Pen]
const INDEX := "Aklat ng Hayop"                               # [Animal Book / Index]
const BACK := "Bumalik"                                       # [Back]
const OK := "Sige"                                            # [OK]
const LOCKED := "Sarado pa"                                   # [Still closed]
const SOON := "Malapit na"                                    # [Coming soon]
const COINS := "Barya: %d"                                    # [Coins: %d]
const CORRECT := "Mahusay!"                                   # [Well done!]
const COINS_EARNED := "+%d barya"                             # [+%d coins]
const NEW_FRIEND := "Bagong kaibigan: %s!"                    # [New friend: %s!]
const COMES_BACK := "Babalik ang pangungusap na ito mamaya."  # [This sentence will come back later.]
const WORKED_EXAMPLE := "Ganito ang sagot:"                   # [Here is how to answer:]
const UNLOCKED := "Bukas na ang %s!"                          # [%s is now open!]
const PEN_EMPTY := "Wala pang hayop dito. Maglaro sa Gubat!"  # [No animals yet. Play in the Forest!]
const NO_ITEMS := "Wala pang pangungusap para rito."          # [No sentences here yet.]
const DRAG_HINT := "Hilahin at bitawan ang pagkain!"          # [Drag and let go of the food!]
const UNKNOWN := "???"

## Stage names shown small at the top of a biome.
const STAGE_NAMES := {
	"vowel": "Patinig",        # [Vowel]
	"consonant": "Katinig",    # [Consonant]
	"wy": "W at Y",            # [W and Y]
	"exception": "Espesyal",   # [Special]
}
