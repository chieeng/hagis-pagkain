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

const BASKET_R := "rin"
const BASKET_D := "din"

# 3D world
const THROW := "Ihagis"                                               # [Throw]
const FOLLOWING := "Sumusunod: %d"                                    # [Following: %d]
const TAKE_HOME := "Dalhin sila sa kulungan!"                          # [Take them to the pen!]
const NO_ANIMAL_NEAR := "Lumapit sa isang hayop!"                     # [Go closer to an animal!]
const TOO_SHORT := "Kulang ang lakas! Subukan ulit."                   # [Not strong enough! Try again.]
const TOO_FAR := "Sobrang lakas! Subukan ulit."                        # [Too strong! Try again.]
const HOLD_TO_THROW := "Pindutin nang matagal, saka bitawan!"         # [Press and hold, then let go!]
const FIRST_KIND := "Tingnan ang kulay ng huling titik!"                 # [Look at the colour of the last letter!]
const NEW_KIND := "Bagong uri ng hayop!"                                  # [A new kind of animal!]
const SENTENCE_PROMPT := "Ihagis ang salitang bubuo sa pangungusap!"  # [Throw the word that completes the sentence!]
const LISTEN := "Pakinggan"                                      # [Listen] (reads the sentence aloud)
const CAUGHT := "NAHULI MO!"                                           # [YOU CAUGHT IT!]
const RARE_CATCH := {"rare": "BIHIRANG HULI!", "golden": "GINTONG HULI!!"}   # [RARE CATCH! / GOLDEN CATCH!!]
const NEW_BADGE := "BAGO!"                                             # [NEW!]
const PERFECT := "PERPEKTO!"                                           # [PERFECT!]
const COMBO := "x%d COMBO"
const MULTIPLIER := "Barya ×%d"                                        # [Coins ×%d]
const RARITY_NAMES := {"common": "Karaniwan", "rare": "Bihira", "golden": "Ginto"}   # [Common, Rare, Golden]
const SHOP := "Tindahan"                                               # [Shop]
const SHOP_TITLE := "Tindahan ng Prutas"                               # [Fruit Shop]
const SHOP_RANGE := "Layo: %d m"                                       # [Distance: %d m]
const SHOP_PRICE := "%d barya"                                         # [%d coins]
const SHOP_BUY := "Bilhin"                                             # [Buy]
const SHOP_USE := "Gamitin"                                            # [Use]
const SHOP_IN_USE := "Gamit na"                                        # [In use]
const SHOP_NOTE := "Mas malayo ang abot ng mas magandang prutas."      # [Better fruit reaches farther.]
const SHOP_BOUGHT := "Nabili: %s!"                                     # [Bought: %s!]

## Stage names shown small at the top of a biome.
const STAGE_NAMES := {
	"vowel": "Patinig",        # [Vowel]
	"consonant": "Katinig",    # [Consonant]
	"wy": "W at Y",            # [W and Y]
	"exception": "Espesyal",   # [Special]
}
