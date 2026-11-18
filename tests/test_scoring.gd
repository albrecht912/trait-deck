extends SceneTree
# Run: godot --headless --path <project> -s res://tests/test_scoring.gd

const TEST_DB := "user://test_scoring.db"
var failed := false

func check(name: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		failed = true

func count(dm, table: String) -> int:
	dm.db.query("SELECT COUNT(*) AS n FROM %s;" % table)
	return int(dm.db.query_result[0]["n"])

func _init() -> void:
	if FileAccess.file_exists(TEST_DB):
		DirAccess.remove_absolute(TEST_DB)
	var dm = preload("res://database_manager.gd").new()
	root.add_child(dm)
	dm.initialize_database(TEST_DB)

	if FileAccess.file_exists("res://data/seed.json"):
		check("seed loads ITEM rows", count(dm, "ITEM") > 0)
	else:
		print("SKIP: seed loads (res://data/seed.json missing)")

	# Own domain row so the test works without the seed (no-op if seeded).
	dm.db.query("INSERT INTO DOMAIN (name) SELECT 'Extraversion' WHERE NOT EXISTS (SELECT 1 FROM DOMAIN WHERE name = 'Extraversion');")
	dm.db.query("INSERT INTO SESSION (student_name) VALUES ('test');")
	dm.active_session_id = dm.db.get_last_insert_rowid()

	dm.log_event("Extraversion", "t", 5.0, 1.0)
	dm.log_event("Extraversion", "t", 1.0, 1.0)
	dm.log_event("Extraversion", "t", 4.0, 2.0)
	check("weighted score is 3.5", is_equal_approx(dm.get_domain_score("Extraversion"), 3.5))
	check("unknown session gives 3.0", dm.get_domain_score("Extraversion", 99999) == 3.0)

	dm.db.query("INSERT INTO SESSION (student_name) VALUES ('test2');")
	var s2: int = dm.db.get_last_insert_rowid()
	var prev: int = dm.active_session_id
	dm.active_session_id = s2
	dm.log_event("Extraversion", "t", 5.0, 0.0)
	check("weight-0 event alone gives 3.0", dm.get_domain_score("Extraversion") == 3.0)
	dm.active_session_id = prev

	var sessions: int = count(dm, "SESSION")
	var logs: int = count(dm, "TELEMETRY_LOG")
	dm.initialize_database(TEST_DB)
	check("re-init keeps sessions and telemetry", count(dm, "SESSION") == sessions and count(dm, "TELEMETRY_LOG") == logs and logs == 4)

	quit(1 if failed else 0)
