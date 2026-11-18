extends Node

var db: SQLite = null
#store data in user PC
const DB_PATH: String = "user://traitdeck_save.db"

#initialize database at start
func _ready():
	initialize_database()

#SQLite connection and generate table
func initialize_database(path: String = DB_PATH):
	db = SQLite.new()
	db.path = path
	db.open_db()
	
	# Enforce Foreign Key Constraints in SQLite (Disabled by default)
	db.query("PRAGMA foreign_keys = ON;")
	
	create_schema_tables()
	migrate()
	load_seed()

func create_schema_tables():
	# 1. DOMAIN Table
	db.query("""
		CREATE TABLE IF NOT EXISTS DOMAIN (
			domain_id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT NOT NULL,
			base_math_val INTEGER DEFAULT 0
		);
	""")
	
	# 2. ITEM Table
	db.query("""
		CREATE TABLE IF NOT EXISTS ITEM (
			item_id INTEGER PRIMARY KEY AUTOINCREMENT,
			domain_id INTEGER NOT NULL,
			item_number INTEGER NOT NULL,
			context_text TEXT NOT NULL,
			is_reverse INTEGER DEFAULT 0,
			FOREIGN KEY (domain_id) REFERENCES DOMAIN(domain_id) ON DELETE CASCADE
		);
	""")
	
	# 3. CARD_OPTION Table
	db.query("""
		CREATE TABLE IF NOT EXISTS CARD_OPTION (
			card_id INTEGER PRIMARY KEY AUTOINCREMENT,
			item_id INTEGER NOT NULL,
			likert_value INTEGER NOT NULL,
			dialogue_text TEXT NOT NULL,
			FOREIGN KEY (item_id) REFERENCES ITEM(item_id) ON DELETE CASCADE
		);
	""")
	
	# 4. SESSION Table
	db.query("""
		CREATE TABLE IF NOT EXISTS SESSION (
			session_id INTEGER PRIMARY KEY AUTOINCREMENT,
			student_name TEXT NOT NULL,
			current_scene INTEGER DEFAULT 1,
			start_time TEXT DEFAULT (datetime('now', 'localtime'))
		);
	""")
	
	# 5. PLAYER_RESPONSE (Associative)
	db.query("""
		CREATE TABLE IF NOT EXISTS PLAYER_RESPONSE (
			session_id INTEGER NOT NULL,
			card_id INTEGER NOT NULL,
			timestamp TEXT DEFAULT (datetime('now', 'localtime')),
			PRIMARY KEY (session_id, card_id),
			FOREIGN KEY (session_id) REFERENCES SESSION(session_id) ON DELETE CASCADE,
			FOREIGN KEY (card_id) REFERENCES CARD_OPTION(card_id) ON DELETE CASCADE
		);
	""")

	# 6. TELEMETRY_LOG
	db.query("""
		CREATE TABLE IF NOT EXISTS TELEMETRY_LOG (
			log_id INTEGER PRIMARY KEY AUTOINCREMENT,
			session_id INTEGER NOT NULL,
			domain_id INTEGER NOT NULL,
			event_type TEXT NOT NULL,
			value REAL NOT NULL,
			weight REAL NOT NULL DEFAULT 1,
			metadata_json TEXT,
			timestamp TEXT DEFAULT (datetime('now', 'localtime')),
			FOREIGN KEY (session_id) REFERENCES SESSION(session_id) ON DELETE CASCADE,
			FOREIGN KEY (domain_id) REFERENCES DOMAIN(domain_id) ON DELETE CASCADE
		);
	""")

	# 7. CARD_EFFECT
	db.query("""
		CREATE TABLE IF NOT EXISTS CARD_EFFECT (
			card_id INTEGER NOT NULL,
			domain_id INTEGER NOT NULL,
			value REAL NOT NULL,
			PRIMARY KEY (card_id, domain_id),
			FOREIGN KEY (card_id) REFERENCES CARD_OPTION(card_id),
			FOREIGN KEY (domain_id) REFERENCES DOMAIN(domain_id)
		);
	""")

## ==========================================
## MIGRATION + SEED
## ==========================================

func migrate():
	db.query("PRAGMA user_version;")
	if int(db.query_result[0]["user_version"]) < 1:
		db.query("ALTER TABLE CARD_OPTION ADD COLUMN requires_item TEXT;")
		db.query("PRAGMA user_version = 1;")

# Primary-key columns per seeded table, in load order.
const SEED_PKS: Dictionary = {
	"DOMAIN": ["domain_id"],
	"ITEM": ["item_id"],
	"CARD_OPTION": ["card_id"],
	"CARD_EFFECT": ["card_id", "domain_id"],
}

# Upsert (not INSERT OR REPLACE) so the FK cascade never wipes PLAYER_RESPONSE.
func load_seed():
	var seed_path: String = "res://data/seed.json"
	if not FileAccess.file_exists(seed_path):
		push_warning("[TraitDeck] Seed file missing: %s" % seed_path)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(seed_path))
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("[TraitDeck] Seed file is not a JSON object.")
		return

	db.query("BEGIN;")
	for table in SEED_PKS:
		var pks: Array = SEED_PKS[table]
		for row in data.get(table, []):
			var cols: Array = row.keys()
			var marks: Array = []
			var updates: Array = []
			var args: Array = []
			for c in cols:
				marks.append("?")
				args.append(row[c])
				if not pks.has(c):
					updates.append("%s = excluded.%s" % [c, c])
			var sql: String = "INSERT INTO %s (%s) VALUES (%s) ON CONFLICT(%s) " % [
				table, ", ".join(cols), ", ".join(marks), ", ".join(pks)]
			sql += ("DO UPDATE SET " + ", ".join(updates)) if not updates.is_empty() else "DO NOTHING"
			db.query_with_bindings(sql + ";", args)
	db.query("COMMIT;")

## ==========================================
## TELEMETRY
## ==========================================

var active_session_id: int = -1

func log_event(domain: String, event_type: String, value: float, weight: float = 1.0, meta: Dictionary = {}) -> void:
	if active_session_id == -1:
		push_warning("[TraitDeck] log_event: no active session.")
		return
	db.query_with_bindings("SELECT domain_id FROM DOMAIN WHERE name = ?;", [domain])
	if db.query_result.is_empty():
		push_warning("[TraitDeck] log_event: unknown domain '%s'." % domain)
		return
	var domain_id: int = int(db.query_result[0]["domain_id"])
	db.query_with_bindings(
		"INSERT INTO TELEMETRY_LOG (session_id, domain_id, event_type, value, weight, metadata_json) VALUES (?, ?, ?, ?, ?, ?);",
		[active_session_id, domain_id, event_type, value, weight, JSON.stringify(meta)])

# Weighted mean of the session's events; weight-0 events are records only.
func get_domain_score(domain: String, session_id: int = active_session_id) -> float:
	db.query_with_bindings(
		"""SELECT SUM(t.value * t.weight) / SUM(t.weight) AS score
		FROM TELEMETRY_LOG t JOIN DOMAIN d ON t.domain_id = d.domain_id
		WHERE t.session_id = ? AND d.name = ?;""",
		[session_id, domain])
	if not db.query_result.is_empty() and db.query_result[0].get("score") != null:
		return float(db.query_result[0]["score"])
	return 3.0
