class_name Hints
extends RefCounted
## Builds the hint shown after a wrong throw (proposal, Part 3 "Hints").
##   Level 1: highlight the last letter (or last syllable for exceptions) + one-line rule.
##   Level 2 (second miss on the same sentence): a worked example.
## Owner: Irish (logic). Filipino wording: Jian + adviser review. Never use "mali" [wrong].

## The deciding letter is shown in the colour of the fruit it takes (the same glow as on the word tags).
static func letter_color(prev_word: String) -> String:
	return GameConfig.R_COLOR if DRRule.takes_r(prev_word) else GameConfig.D_COLOR

## English for the team: vowel -> r | w or y -> r | consonant -> d | -ra, -ri, -raw, -ray -> d
const RULE_LINES := {
	"vowel": "Nagtatapos sa patinig (a, e, i, o, u) → r",
	"wy": "Nagtatapos sa w o y → r",
	"consonant": "Nagtatapos sa katinig → d",
	"exception": "Nagtatapos sa -ra, -ri, -raw o -ray → d",
}


static func rule_line(prev_word: String) -> String:
	return RULE_LINES[DRRule.stage(prev_word)]


## "Tingnan ang huling titik!" [Look at the last letter!] or "...pantig!" [...syllable!]
static func title(prev_word: String) -> String:
	if DRRule.stage(prev_word) == "exception":
		return "Tingnan ang huling pantig!"
	return "Tingnan ang huling titik!"


## "ikaw" -> "ika[color][b]w[/b][/color]"
static func highlight_word(word: String) -> String:
	var n: int = min(DRRule.deciding_length(word), word.length())
	return "%s[color=%s][b]%s[/b][/color]" % [word.left(word.length() - n), letter_color(word), word.right(n)]


## The sentence with prev_word highlighted and the blank replaced by `fill`.
static func highlighted_sentence(item: Dictionary, fill: String = "___") -> String:
	var s: String = item.sentence
	var prev: String = item.prev_word
	var blank := s.find("___")
	var start := s.rfind(prev, blank)
	if blank == -1 or start == -1:
		return s.replace("___", fill)
	return s.left(start) + highlight_word(prev) + s.substr(start + prev.length()).replace("___", fill)


## Three short steps that solve this sentence.
static func worked_example(item: Dictionary) -> Array[String]:
	var prev: String = item.prev_word
	var n: int = min(DRRule.deciding_length(prev), prev.length())
	var unit := "pantig" if DRRule.stage(prev) == "exception" else "titik"
	var lines: Array[String] = []
	lines.append("1. Huling %s ng [b]%s[/b]: [color=%s][b]%s[/b][/color]" % [unit, prev, letter_color(prev), prev.right(n)])
	lines.append("2. " + rule_line(prev))
	lines.append("3. " + highlighted_sentence(item, "[b]%s[/b]" % item.answer))
	return lines
