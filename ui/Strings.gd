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

# Lesson (Aralin) before a biome
const LESSON := "Aralin"                                               # [Lesson]
const LESSON_TITLE := "Aralin: din at rin"                             # [Lesson: din and rin]
const LESSON_STEPS := ["1. Tingnan", "2. Hanapin", "3. Ayusin", "4. Maglaro"]  # [Look, Find, Sort, Play]
const LESSON_LOOK := "Tingnan ang huling titik ng salita bago ang din o rin."  # [Look at the last letter of the word before din or rin.]
const LESSON_FIND := "Pindutin ang huling titik!"                     # [Tap the last letter!]
const LESSON_FIND_AGAIN := "Nasa dulo ang huling titik."              # [The last letter is at the end.]
const LESSON_SORT := "Hilahin ang salita sa tamang basket."            # [Drag the word into the right basket.]
const LESSON_SORT_HELP := "Tingnan ang huling titik, saka pumili ng basket."  # [Look at the last letter, then pick a basket.]
const LESSON_READY := "Handa ka na! Pakainin ang mga hayop sa Gubat."  # [You're ready! Feed the animals in the Forest.]
const LESSON_GO := "Maglaro na!"                                      # [Let's play!]
const BASKET_R := "rin"
const BASKET_D := "din"

# 3D world
const THROW := "Ihagis"                                               # [Throw]
const FOLLOWING := "Sumusunod: %d"                                    # [Following: %d]
const TAKE_HOME := "Dalhin sila sa kulungan!"                          # [Take them to the pen!]
const NO_ANIMAL_NEAR := "Lumapit sa isang hayop!"                     # [Go closer to an animal!]

## Stage names shown small at the top of a biome.
const STAGE_NAMES := {
	"vowel": "Patinig",        # [Vowel]
	"consonant": "Katinig",    # [Consonant]
	"wy": "W at Y",            # [W and Y]
	"exception": "Espesyal",   # [Special]
}
