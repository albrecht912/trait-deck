extends SceneTree
# Run: godot --headless --path <project> -s res://tests/test_tracker.gd

var failed := false

func check(name: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		failed = true

func _initialize() -> void:
	await process_frame
	var dm = root.get_node("DatabaseManager")
	var tt = root.get_node("TelemetryTracker")
	check("proximity 1.0 -> 5", tt.proximity_to_value(1.0) == 5.0)
	check("proximity 8.0 -> 1", tt.proximity_to_value(8.0) == 1.0)
	check("proximity 4.75 -> 3", is_equal_approx(tt.proximity_to_value(4.75), 3.0))
	check("proximity 20 -> 1", tt.proximity_to_value(20) == 1.0)
	check("ratio 1/4 -> 2", tt.ratio_to_value(1, 4) == 2.0)
	check("ratio 4/4 -> 5", tt.ratio_to_value(4, 4) == 5.0)
	check("ratio 0/3 -> 1", tt.ratio_to_value(0, 3) == 1.0)
	dm.db.query("INSERT INTO SESSION (student_name) VALUES ('test_tracker');")
	dm.active_session_id = dm.db.get_last_insert_rowid()

	var room := Node3D.new()
	room.name = "room"
	var crowd := Marker3D.new()
	crowd.add_to_group("crowd")
	room.add_child(crowd)
	var npc = load("res://scenes/optional_interactable.tscn").instantiate()
	npc.kind = "npc"
	npc.interact_id = "test_npc"
	room.add_child(npc)
	var player := Node3D.new()
	player.position = Vector3(1, 0, 0)
	root.add_child(room)
	root.add_child(player)

	tt.begin_room(room, player)
	await create_timer(1.2).timeout
	tt.end_room()
	check("crowd at 1 m gives Extraversion 5", dm.get_domain_score("Extraversion") == 5.0)
	check("first interaction returns true", tt.mark_interacted("npc", "test_npc"))
	check("repeat interaction returns false", not tt.mark_interacted("npc", "test_npc"))
	tt.finish()
	dm.db.query_with_bindings("SELECT COUNT(*) AS n FROM TELEMETRY_LOG WHERE event_type = 'optional_npc_ratio' AND session_id = ?;", [dm.active_session_id])
	check("optional_npc_ratio logged", int(dm.db.query_result[0]["n"]) == 1)
	tt.reset()

	quit(1 if failed else 0)
