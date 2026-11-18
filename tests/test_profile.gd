extends SceneTree
# Run: godot --headless --path <project> -s res://tests/test_profile.gd

var failed := false

func check(name: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		failed = true

func _initialize() -> void:
	await process_frame
	var tp = load("res://trait_profile.gd")
	var neutral := {"Extraversion": 3.0, "Agreeableness": 3.0, "Conscientiousness": 3.0, "Negative Emotionality": 3.0, "Open-Mindedness": 3.0}
	check("all mid -> no dominant", tp.dominant(neutral) == "")
	check("all mid -> balanced title", tp.archetype(neutral) == tp.BALANCED_TITLE)

	var s := neutral.duplicate()
	s["Agreeableness"] = 4.5
	s["Extraversion"] = 1.8  # deviation 1.2 < 1.5
	check("largest deviation wins", tp.dominant(s) == "Agreeableness:high")
	check("archetype from dominant", tp.archetype(s) == "The Gentle Brother")
	s["Extraversion"] = 1.2
	check("low trait can dominate", tp.dominant(s) == "Extraversion:low")

	var text: String = tp.summary(s, {14: 5, 13: 3, 15: 1})
	check("summary has high moment", text.contains("starving kitten"))
	check("summary has low moment", text.contains("lost freshman to someone else"))
	check("neutral choice adds no moment", not text.contains("queue"))
	check("haris line by dominant", tp.haris_line(3, s).contains("listen tonight"))
	check("no haris line -> empty", tp.haris_line(1, s) == "")

	quit(1 if failed else 0)
