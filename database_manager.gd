extends Node

var db: SQLite = null
#store data in user PC
const DB_PATH: String = "user://traitdeck_save.db"

#initialize database at start
func _ready():
	initialize_database()

#SQLite connection and generate table
func initialize_database():
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()
	
	# Enforce Foreign Key Constraints in SQLite (Disabled by default)
	db.query("PRAGMA foreign_keys = ON;")
	
	create_schema_tables()

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
