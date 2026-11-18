extends CanvasLayer
class_name InventoryHUD

## Bottom bar with one slot per inventory item plus a "Found: <name>" toast on pickup.

const INK := Color(0.29, 0.231, 0.2, 1)
const SLOT := 44.0

@onready var _bar: PanelContainer = $Root/Bar
@onready var _slots: HBoxContainer = $Root/Bar/Slots
@onready var _toast: PanelContainer = $Root/Toast
@onready var _toast_label: Label = $Root/Toast/Label

var _icons: Dictionary = {}
var _tween: Tween

static func _box(color: Color, radius: int, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(8)
	if border.a > 0.0:
		sb.set_border_width_all(2)
		sb.border_color = border
	return sb

func _ready() -> void:
	_bar.add_theme_stylebox_override("panel", _box(Color("FFE8A3", 0.9), 20, Color("D9B84E")))
	_toast.add_theme_stylebox_override("panel", _box(Color("FFF3DC"), 22, Color("F5BE3A")))
	_toast_label.add_theme_color_override("font_color", INK)
	_toast_label.add_theme_font_size_override("font_size", 28)
	for id: String in InventoryManager.ITEMS:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(SLOT, SLOT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var path := "res://assets/ui/icons/%s.svg" % id
		if ResourceLoader.exists(path):
			icon.texture = load(path)
		_slots.add_child(icon)
		_icons[id] = icon
	_toast.visible = false
	InventoryManager.item_added.connect(_on_item_added)
	_refresh()

func _process(_delta: float) -> void:
	# InventoryManager.clear() (restart) emits no signal, so resync when the count drops.
	if _slots.get_children().filter(func(n): return n.modulate.a == 1.0).size() != InventoryManager.found.size():
		_refresh()

func _refresh() -> void:
	for id: String in _icons:
		_icons[id].modulate.a = 1.0 if InventoryManager.was_found(id) else 0.18

func _on_item_added(id: String) -> void:
	_refresh()
	_toast_label.text = "Found: %s" % InventoryManager.ITEMS[id]
	_toast.reset_size()
	_toast.visible = true
	var x := (get_viewport().get_visible_rect().size.x - _toast.size.x) * 0.5
	_toast.position = Vector2(x, -_toast.size.y - 8.0)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_toast, "position:y", 24.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(1.8)
	_tween.tween_property(_toast, "position:y", -_toast.size.y - 8.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func(): _toast.visible = false)
