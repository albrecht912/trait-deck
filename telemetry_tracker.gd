extends Node

## Feeds Extraversion (crowd proximity, optional NPCs) and Open-Mindedness (optional POIs,
## collectibles) into TELEMETRY_LOG. SessionManager brackets each room with begin_room/end_room.

const NEAR_M := 1.5
const FAR_M := 8.0
const SAMPLE_SEC := 0.5
const KIND_GROUPS := {"poi": "optional_poi", "npc": "optional_npc", "collectible": "collectible"}

var room: Node
var player: Node3D
var samples: Array[float] = []
var available := {"poi": {}, "npc": {}, "collectible": {}}
var interacted := {"poi": {}, "npc": {}}
var tidied := {}        # task_id -> true; read by TidyTask so tidied objects stay tidy on room reload
var tidy_scored := {}   # room name -> true; a room's tidiness is scored on the first visit only
var _timer: Timer

static func proximity_to_value(d: float) -> float:
	return 1.0 + 4.0 * clampf((FAR_M - d) / (FAR_M - NEAR_M), 0.0, 1.0)

static func ratio_to_value(found: int, available_count: int) -> float:
	return 1.0 + 4.0 * found / available_count

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = SAMPLE_SEC
	_timer.timeout.connect(_sample)
	add_child(_timer)

func begin_room(r: Node, p: Node3D) -> void:
	room = r
	player = p
	samples.clear()
	for kind in KIND_GROUPS:
		for n in get_tree().get_nodes_in_group(KIND_GROUPS[kind]):
			if r.is_ancestor_of(n):
				available[kind][n.item_id if kind == "collectible" else n.interact_id] = true
	_timer.start()

func _sample() -> void:
	if not is_instance_valid(room) or not is_instance_valid(player):
		return
	var best := INF
	for n in get_tree().get_nodes_in_group("crowd"):
		if n is Node3D and room.is_ancestor_of(n):
			best = minf(best, player.global_position.distance_to(n.global_position))
	if best < INF:
		samples.append(best)

func end_room() -> void:
	_timer.stop()
	if not samples.is_empty():
		var avg := 0.0
		for s in samples:
			avg += s
		avg /= samples.size()
		print("[TraitDeck] Crowd proximity in %s: avg %.2f m over %d samples -> E %.2f" % [room.name, avg, samples.size(), proximity_to_value(avg)])
		DatabaseManager.log_event("Extraversion", "crowd_proximity", proximity_to_value(avg), 1.0,
			{"room": room.name, "avg_m": avg, "samples": samples.size()})
	samples.clear()
	if is_instance_valid(room) and not tidy_scored.has(room.name):
		var total := 0
		var done := 0
		for n in get_tree().get_nodes_in_group("tidy_task"):
			if room.is_ancestor_of(n):
				total += 1
				done += int(tidied.has(n.task_id))
		if total > 0:
			tidy_scored[room.name] = true
			print("[TraitDeck] Tidy in %s: %d/%d -> C %.2f" % [room.name, done, total, ratio_to_value(done, total)])
			DatabaseManager.log_event("Conscientiousness", "room_tidy", ratio_to_value(done, total), 1.0,
				{"room": room.name, "done": done, "total": total})

func mark_interacted(kind: String, id: String) -> bool:
	if interacted[kind].has(id):
		return false
	interacted[kind][id] = true
	DatabaseManager.log_event("Open-Mindedness" if kind == "poi" else "Extraversion", "optional_" + kind, 5.0, 0.0, {"id": id})
	return true

func finish() -> void:
	end_room()
	var found_coll := 0
	for id in InventoryManager.found:
		if available["collectible"].has(id):
			found_coll += 1
	var found: int = interacted["poi"].size() + found_coll
	var total: int = available["poi"].size() + available["collectible"].size()
	if total > 0:
		DatabaseManager.log_event("Open-Mindedness", "exploration_ratio", ratio_to_value(found, total), 1.0,
			{"found": found, "available": total})
	var npcs: int = available["npc"].size()
	if npcs > 0:
		DatabaseManager.log_event("Extraversion", "optional_npc_ratio", ratio_to_value(interacted["npc"].size(), npcs), 1.0,
			{"found": interacted["npc"].size(), "available": npcs})

func reset() -> void:
	_timer.stop()
	samples.clear()
	room = null
	player = null
	tidied.clear()
	tidy_scored.clear()
	for d in available.values() + interacted.values():
		d.clear()
