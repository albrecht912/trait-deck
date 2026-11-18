extends SceneTree
# Run: godot --headless --path <project> -s res://tests/test_qte.gd

var failed := false

func check(name: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		failed = true

func _initialize() -> void:
	await process_frame  # autoload names are only resolvable after the first frame
	var dm = root.get_node("DatabaseManager")
	var qte_script = load("res://scenes/ui/qte_ui.gd")
	check("instant success -> N 1", qte_script.reaction_to_n(0.0, 2.0, true) == 1.0)
	check("half-window success -> N 2.5", qte_script.reaction_to_n(1.0, 2.0, true) == 2.5)
	check("miss -> N 5", qte_script.reaction_to_n(2.0, 2.0, false) == 5.0)

	var qte = load("res://scenes/ui/qte_ui.tscn").instantiate()
	root.add_child(qte)

	create_timer(0.3).timeout.connect(qte.press)
	var r: Dictionary = await qte.run("p", "a", 1.0)
	# Lower bound is loose: the first headless frame's long delta can fire the 0.3 s timer early.
	check("press in window succeeds", r["success"] and r["reaction_sec"] > 0.0 and r["reaction_sec"] < 1.0)

	r = await qte.run("p", "a", 0.4)
	check("no press times out as miss", not r["success"])

	# Run 1's timer (0.5 s) must not fail run 2 (2 s window, pressed at 0.8 s).
	create_timer(0.1).timeout.connect(qte.press)
	await qte.run("p", "a", 0.5)
	create_timer(0.8).timeout.connect(qte.press)
	r = await qte.run("p", "a", 2.0)
	check("stale timer does not fail the next QTE", r["success"])

	# Full sequence, no presses: both QTEs miss; carried the only available prep item.
	dm.db.query("INSERT INTO SESSION (student_name) VALUES ('test_qte');")
	dm.active_session_id = dm.db.get_last_insert_rowid()
	root.get_node("TelemetryTracker").available["collectible"]["electrolyte_sachet"] = true
	root.get_node("InventoryManager").items.append("electrolyte_sachet")
	await qte.run_sequence("rain_collapse")
	check("two misses -> N 5", dm.get_domain_score("Negative Emotionality") == 5.0)
	check("missed check (1) + full preparation (5) -> C 3", dm.get_domain_score("Conscientiousness") == 3.0)
	root.get_node("TelemetryTracker").reset()
	root.get_node("InventoryManager").clear()

	quit(1 if failed else 0)
