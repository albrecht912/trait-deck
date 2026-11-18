class_name TraitProfile

## Turns a {domain_name: 1–5 score} dictionary into narrative output:
## dominant trait, Haris's flavour lines, archetype title and character summary.
## All text below is a DRAFT for the author to rewrite.

const DOMAINS := ["Extraversion", "Agreeableness", "Conscientiousness", "Negative Emotionality", "Open-Mindedness"]
const HIGH := 3.67  # BFI-2 style bands on the 1–5 scale
const LOW := 2.33

const ARCHETYPES := {
	"Extraversion:high": "The Spark of the Mahallah",
	"Extraversion:low": "The Quiet Observer",
	"Agreeableness:high": "The Gentle Brother",
	"Agreeableness:low": "The Straight Shooter",
	"Conscientiousness:high": "The Dependable Anchor",
	"Conscientiousness:low": "The Free Spirit",
	"Negative Emotionality:high": "The Feeling Heart",
	"Negative Emotionality:low": "The Steady Hand",
	"Open-Mindedness:high": "The Curious Wanderer",
	"Open-Mindedness:low": "The Grounded Traditionalist",
}
const BALANCED_TITLE := "The Steady Newcomer"

const TRAIT_SENTENCES := {
	"Extraversion": {
		"high": "You stepped toward the crowd instead of away from it, and the hall at SHAS Mosque started to feel like yours.",
		"mid": "You found your voice when it mattered, and kept your quiet when you needed it.",
		"low": "You moved through the crowds carefully, saving your energy for the people who mattered most.",
	},
	"Agreeableness": {
		"high": "Kindness came first: for a lost freshman, a starving kitten and a roommate who wouldn't admit he was hurting.",
		"mid": "You balanced fairness with warmth, standing your ground without forgetting others.",
		"low": "You said what needed saying, even when a softer word would have been easier.",
	},
	"Conscientiousness": {
		"high": "You came prepared: room in order, notes taken, the right thing in your bag when it counted.",
		"mid": "You kept on top of what mattered most, even if not every corner was tidy.",
		"low": "You lived the week in the moment, trusting yourself to figure things out as they came.",
	},
	"Negative Emotionality": {
		"high": "The week weighed on you, and you felt every moment of it — yet you kept showing up.",
		"mid": "Your nerves rose and settled; you bent without breaking.",
		"low": "When the storm hit, you kept a level head while everything around you shook.",
	},
	"Open-Mindedness": {
		"high": "You wandered off the marked path, noticing noticeboards, balconies and details others walked past.",
		"mid": "You explored when something caught your eye, and stayed on course when time was short.",
		"low": "You kept to the path you knew, focused on getting where you needed to be.",
	},
}

## Specific story moments, keyed by ITEM id; "high" if the chosen card's likert >= 4, "low" if <= 2.
const MOMENTS := {
	13: {"high": "You spoke up for Haris in the RHB queue.", "low": "You let the queue-cutter pass, keeping the peace."},
	14: {"high": "You knelt for a starving kitten while Maghrib drew near.", "low": "You hurried past the kitten under the bench."},
	15: {"high": "You walked a lost freshman to the right Kulliyyah.", "low": "You left the lost freshman to someone else."},
}

## Haris's flavour lines per ITEM id, chosen by the player's dominant trait.
const HARIS_LINES := {
	3: {
		"Extraversion:high": "Haris grins: \"You're getting used to the noise around here, bro.\"",
		"Extraversion:low": "Haris nudges you: \"It's okay to just listen tonight. I'll do the talking.\"",
		"Negative Emotionality:high": "Haris whispers: \"Nervous about tomorrow? Me too, honestly.\"",
	},
	13: {
		"Agreeableness:high": "Haris mutters, pale: \"Don't start a fight for me, okay?\"",
		"Extraversion:high": "Haris leans on the pillar: \"You've got this, bro. I'll just... sit for a sec.\"",
		"Conscientiousness:high": "Haris checks the queue number you noted earlier: \"At least someone's organised.\"",
	},
	14: {
		"Agreeableness:high": "Haris smiles weakly: \"Of course you'd stop. Go on, I'll rest here.\"",
		"Conscientiousness:high": "Haris glances at his watch: \"Five minutes, then we run for Maghrib.\"",
	},
	12: {
		"Extraversion:high": "Haris laughs: \"Look at you, front row. Who are you and what did you do with my roommate?\"",
		"Negative Emotionality:low": "Haris taps his pocket: \"Took my meds. Thanks for keeping your head on Thursday.\"",
		"Negative Emotionality:high": "Haris squeezes your shoulder: \"We made it. Both of us.\"",
	},
}

static func band(score: float) -> String:
	return "high" if score >= HIGH else ("low" if score <= LOW else "mid")

## The domain furthest from the neutral 3.0, as "Domain:high|low"; "" if every score is mid-band.
static func dominant(scores: Dictionary) -> String:
	var best := ""
	var best_dev := 0.0
	for d in DOMAINS:
		var dev: float = absf(scores.get(d, 3.0) - 3.0)
		if band(scores.get(d, 3.0)) != "mid" and dev > best_dev:
			best_dev = dev
			best = "%s:%s" % [d, band(scores[d])]
	return best

static func archetype(scores: Dictionary) -> String:
	return ARCHETYPES.get(dominant(scores), BALANCED_TITLE)

## choices: {item_id: likert of the chosen card}.
static func summary(scores: Dictionary, choices: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in MOMENTS:
		if choices.has(item_id) and choices[item_id] != 3:
			parts.append(MOMENTS[item_id]["high" if choices[item_id] >= 4 else "low"])
	for d in DOMAINS:
		parts.append(TRAIT_SENTENCES[d][band(scores.get(d, 3.0))])
	return " ".join(parts)

static func haris_line(item_id: int, scores: Dictionary) -> String:
	return HARIS_LINES.get(item_id, {}).get(dominant(scores), "")
