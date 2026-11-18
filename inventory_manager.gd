extends Node

const ITEMS := {
	"highlighter_pen": "Highlighting Pen",
	"wet_wipes": "Wet Wipes",
	"adapter_plug": "3-Pin Adapter",
	"cat_treats": "Cat Treats",
	"campus_map": "Campus Map Leaflet",
	"pocket_notebook": "Pocket Notebook",
	"electrolyte_sachet": "Electrolyte Sachet",
	"plastic_dish": "Small Plastic Dish",
	"lozenges": "Dextrose Tablets",
	"umbrella": "Foldable Umbrella",
	"flashlight_whistle": "Flashlight & Whistle",
	"ors_packets": "ORS Packets",
	"lapel_pin": "Ta'aruf Lapel Pin",
	"club_handbook": "Club Handbook",
}

signal item_added(id: String)

var items: Array[String] = []
var found: Array[String] = []

func add(id: String) -> void:
	assert(ITEMS.has(id), "Unknown item id: %s" % id)
	if found.has(id):
		return
	found.append(id)
	items.append(id)
	item_added.emit(id)
	# weight 0: Phase 3 will score the found/available ratio instead.
	DatabaseManager.log_event("Open-Mindedness", "collectible_found", 5.0, 0.0, {"item": id})

func was_found(id: String) -> bool:
	return found.has(id)

func has(id: String) -> bool:
	return items.has(id)

func consume(id: String) -> bool:
	if not items.has(id):
		return false
	items.erase(id)
	return true

func clear() -> void:
	items.clear()
	found.clear()
