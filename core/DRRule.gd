class_name DRRule
extends RefCounted
## Owner: Irish (Systems). Any change needs a new test in tests/test_dr_rule.gd.
##
## Decides the KWF *preferred standard form* of a d/r particle.
## Source: KWF Manwal sa Masinop na Pagsulat (2014), sec. 8.1-8.2, pp. 35-36;
##         Ortograpiyang Pambansa (2013), pp. 34-35.
##
## Rule:
##   - Previous word ends in a vowel or in w/y  -> r-form  (masaya rin, ikaw raw, bahay rito)
##   - Previous word ends in any other consonant -> d-form (pinsan din)
##   - KWF exception: previous word ends in -ra, -ri, -raw, -ray -> d-form (mura din)
##     -ro and -re are NOT KWF exceptions (some secondary sources list them; we do not).
##
## KWF also says the d-form after a vowel is not an error. Feedback must say
## "preferred form", never "wrong".

## d-form -> r-form
const PAIRS := {
	"din": "rin",
	"daw": "raw",
	"dito": "rito",
	"diyan": "riyan",
	"doon": "roon",
}
const VOWELS := "aeiou"
const SEMIVOWELS := "wy"
const KWF_EXCEPTION_ENDINGS := ["ra", "ri", "raw", "ray"]

const REASON_VOWEL := "after_vowel"
const REASON_SEMIVOWEL := "after_semivowel"
const REASON_CONSONANT := "after_consonant"
const REASON_EXCEPTION := "kwf_exception"


## Lowercases and strips punctuation/spaces around a word: "Masaya," -> "masaya".
static func clean_word(word: String) -> String:
	var re := RegEx.new()
	re.compile("^[^a-zñ]+|[^a-zñ]+$")
	return re.sub(word.strip_edges().to_lower(), "", true)


## Returns the d-form of either member of a pair ("rin" -> "din"), or "" if unknown.
static func d_form(particle: String) -> String:
	var p := clean_word(particle)
	if PAIRS.has(p):
		return p
	for d in PAIRS:
		if PAIRS[d] == p:
			return d
	return ""


## Returns the r-form of either member of a pair ("din" -> "rin"), or "" if unknown.
static func r_form(particle: String) -> String:
	var d := d_form(particle)
	return PAIRS[d] if d != "" else ""


static func is_supported(particle: String) -> bool:
	return d_form(particle) != ""


## Why the rule picks d or r after this word. Use it for feedback text and item tags.
static func reason(prev_word: String) -> String:
	var w := clean_word(prev_word)
	if w.is_empty():
		return REASON_CONSONANT
	for ending in KWF_EXCEPTION_ENDINGS:
		if w.ends_with(ending):
			return REASON_EXCEPTION
	var last := w.right(1)
	if VOWELS.contains(last):
		return REASON_VOWEL
	if SEMIVOWELS.contains(last):
		return REASON_SEMIVOWEL
	return REASON_CONSONANT


static func takes_r(prev_word: String) -> bool:
	var r := reason(prev_word)
	return r == REASON_VOWEL or r == REASON_SEMIVOWEL


## The preferred form of `particle` (either "din" or "rin" works) after `prev_word`.
static func preferred_form(prev_word: String, particle: String) -> String:
	var d := d_form(particle)
	if d == "":
		push_error("DRRule: unsupported particle '%s'" % particle)
		return ""
	return PAIRS[d] if takes_r(prev_word) else d


static func is_preferred(prev_word: String, chosen: String) -> bool:
	return is_supported(chosen) and clean_word(chosen) == preferred_form(prev_word, chosen)
