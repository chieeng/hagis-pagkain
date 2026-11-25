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

# 3D zones [redesign 2026-11-25: walk, collect word tiles, repair the way]
const FOLLOWING := "Sumusunod: %d"                                    # [Following: %d]
const FIRST_KIND := "Tingnan ang kulay ng huling titik!"                 # [Look at the colour of the last letter!]
const NEW_KIND := "Bagong uri ng hayop!"                                  # [A new kind of animal!]
const SENTENCE_PROMPT := "Piliin ang salitang bubuo sa pangungusap!"  # [Pick the word that completes the sentence!]
const LISTEN := "Pakinggan"                                      # [Listen] (reads the sentence aloud)
const RESCUED := "NAILIGTAS MO!"                                       # [YOU RESCUED IT!]
const RARE_RESCUE := {"rare": "BIHIRANG SAGIP!", "golden": "GINTONG SAGIP!!"}   # [RARE RESCUE! / GOLDEN RESCUE!!]
const NEW_BADGE := "BAGO!"                                             # [NEW!]
const COMBO := "x%d COMBO"
const POUCH := "Mga salita:"                                           # [Your words:]
const TILE_GET := "Nakuha: %s!"                                        # [Got: %s!]
const GO_NEAR_SLOT := "Lumapit sa sirang bahagi!"                      # [Go to the broken part!]
const NEED_TILE := "Hanapin muna ang mga salita sa paligid!"           # [Find the words around you first!]
const BRIDGE_DONE := "Nabuo ang daan!"                                 # [The way is built!]
const TRAPPED := "Iligtas mo ako!"                                     # [Rescue me!]
const WALK_IN := "Pumasok sa portal!"                                  # [Walk into the portal!]
const HUB_TITLE := "Piliin ang iyong paglalakbay"                      # [Choose your journey]
const MULTIPLIER := "Barya ×%d"                                        # [Coins ×%d]
const RARITY_NAMES := {"common": "Karaniwan", "rare": "Bihira", "golden": "Ginto"}   # [Common, Rare, Golden]
const SHOP := "Tindahan"                                               # [Shop]
const SHOP_TITLE := "Tindahan ng Prutas"                               # [Fruit Shop]
const SHOP_SPEED := "Bilis: ×%.1f"                                     # [Speed: ×%.1f]
const SHOP_PRICE := "%d barya"                                         # [%d coins]
const SHOP_BUY := "Bilhin"                                             # [Buy]
const SHOP_USE := "Gamitin"                                            # [Use]
const SHOP_IN_USE := "Gamit na"                                        # [In use]
const SHOP_NOTE := "Mas mabilis maglakad kapag masarap ang baon!"      # [You walk faster with a tasty snack!]
const SHOP_BOUGHT := "Nabili: %s!"                                     # [Bought: %s!]

# Biome-select screen [proposal: shows progress per biome; locked biomes say what is needed]
const PROGRESS_ANIMALS := "%d/%d hayop"                          # [%d/%d animals]
const PROGRESS_SENTENCES := "%d pangungusap"                     # [%d sentences answered]
const NEED_PREV := "Tapusin muna ang %s"                          # [Finish %s first]
const NEED_INDEX := "Kumpletuhin ang Aklat ng Hayop"              # [Complete the Animal Index]
const NEED_ACCURACY := "Abutin ang 80% sa bawat yugto"            # [Reach 80% in every stage]
const PLAY_AGAIN := "Maglaro ulit"                                # [Play again]

# My Progress screen [proposal: accuracy per pair and per context, sentences to review next]
const MY_PROGRESS := "Aking Pag-unlad"                            # [My Progress]
const REVIEW_NEXT := "Balikan ang mga pangungusap na ito:"        # [Review these sentences next:]
const NO_DATA := "—"
const NOTHING_TO_REVIEW := "Wala! Tuloy lang sa paglalaro."       # [Nothing! Keep playing.]
const CONTEXT := "Yugto"                                          # [Stage/Context]
const PAIR := "Pares"                                             # [Pair]

## Stage names shown small at the top of a biome.
const STAGE_NAMES := {
	"vowel": "Patinig",        # [Vowel]
	"consonant": "Katinig",    # [Consonant]
	"wy": "W at Y",            # [W and Y]
	"exception": "Espesyal",   # [Special]
}
