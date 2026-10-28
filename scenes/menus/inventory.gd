extends RazinoScreen
## UI-19 — موجودی, laid out as the approved sheet's inventory panel.
##
## The sheet's arrangement, left to right in reading order: a header with a
## round glyph beside the name, a row of tabs with only the active one lit,
## a four-column grid of slots inside its own sunken well, and beside it a
## detail panel holding the selected object large, its name, what it does,
## and the one gold button on the screen.

const TABS := ["همه", "وسایل", "سرنخ‌ها", "یادداشت‌ها"]
const COLUMNS := 4
const ROWS := 4

## What each item the content can hand out is called and what it does, for
## the detail panel. The art comes from ItemArt.
const ITEMS := {
	"ITEM_MAP_PIECE": {"name": "تکهٔ نقشه", "glyph": "map",
		"about": "گوشه‌ای از یک نقشهٔ قدیمی. انگار بخشی از آن بریده شده."},
	"ITEM_NOTEBOOK": {"name": "دفترچه", "glyph": "book",
		"about": "دفترچهٔ کوچکی با چند صفحهٔ کنده‌شده."},
	"ITEM_BRASS_KEY": {"name": "کلید برنجی", "glyph": "key",
		"about": "کلیدی سنگین با دندانه‌های نامتعارف."},
	"ITEM_GEAR_TEN": {"name": "چرخ‌دندهٔ دهم", "glyph": "gem",
		"about": "چرخ‌دنده‌ای که جای خالی‌اش در دستگاه برج پیداست."},
	"ITEM_TOOLS": {"name": "جعبه‌ابزار", "glyph": "box",
		"about": "ابزار مانی. با آن می‌شود یک مانع مکانیکی را باز کرد."},
	"ITEM_LEVER": {"name": "اهرم", "glyph": "box", "about": "اهرمی از جنس برنج."},
	"ITEM_UNDERMAP": {"name": "نقشهٔ زیرزمین", "glyph": "map",
		"about": "راه‌های زیر شهر، کشیده‌شده با دست."},
	"ITEM_RECORDER": {"name": "ضبط‌کننده", "glyph": "magnifier",
		"about": "دستگاهی که صداها را نگه می‌دارد."},
	"ITEM_TENTH_KEY": {"name": "کلید دهم", "glyph": "key",
		"about": "آخرین کلید. جایی در برج قفلی منتظرش است."},
}

var _tab: int = 0
var _selected: String = ""
var _tab_row: HBoxContainer
var _grid: GridContainer
var _detail: VBoxContainer

func _ready() -> void:
	configure("موجودی", "UI-04", "panel", true, "backpack")
	super._ready()

func build_content() -> void:
	_tab_row = HBoxContainer.new()
	_tab_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_tab_row.add_theme_constant_override("separation", Palette.PAD_SM)
	content.add_child(_tab_row)

	var body := HBoxContainer.new()
	body.layout_direction = Control.LAYOUT_DIRECTION_RTL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.PAD_MD)
	content.add_child(body)

	# — the grid, in its own sunken well —
	var well := PanelContainer.new()
	well.add_theme_stylebox_override("panel", Style._box(
		OrnateBox.Kind.PANEL, Palette.PANEL_DEEP, Palette.NIGHT,
		RazinoUI.RADIUS, 0.0, 16, 16))
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(well)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	well.add_child(_grid)

	# — the detail panel —
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Style._box(
		OrnateBox.Kind.PANEL, Palette.PANEL_DEEP, Palette.NIGHT,
		RazinoUI.RADIUS, 0.0, 18, 16))
	card.custom_minimum_size.x = 340
	body.add_child(card)
	_detail = VBoxContainer.new()
	_detail.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_detail.add_theme_constant_override("separation", Palette.PAD_MD)
	card.add_child(_detail)

	_build_tabs()
	_build_grid()

func _build_tabs() -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	var buttons := Style.make_tabs(TABS, _tab)
	for i in buttons.size():
		var index := i
		buttons[i].pressed.connect(func():
			_tab = index
			_selected = ""
			_build_tabs()
			_build_grid())
		_tab_row.add_child(buttons[i])

func _build_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var held := _held()
	if _selected.is_empty() and not held.is_empty():
		_selected = String(held[0])

	for i in COLUMNS * ROWS:
		var slot: Control
		if i < held.size():
			var id := String(held[i])
			slot = _slot(id, id == _selected)
		else:
			slot = Style.make_item_slot("", 0, 86.0)
		_grid.add_child(slot)
	_build_detail()

## Which ids this tab shows. Clues and notes have their own screens, so the
## tabs that point at them say so rather than showing an empty grid.
func _held() -> Array:
	match _tab:
		1: return GameState.inventory.keys()
		2: return GameState.clues.keys()
		3: return []
		_: return GameState.inventory.keys() + GameState.clues.keys()

func _slot(id: String, chosen: bool) -> Control:
	var entry: Dictionary = ITEMS.get(id, {})
	var glyph := String(entry.get("glyph", "magnifier"))
	var b := Button.new()
	b.custom_minimum_size = Vector2(86, 86)
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var tile := Style.make_item_slot(glyph, 0, 86.0)
	tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tile)
	if chosen:
		var ring := _Chosen.new()
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ring)
	b.pressed.connect(func():
		_selected = id
		AudioManager.play_sfx("SFX_UI_TAP")
		_build_grid())
	return b

func _build_detail() -> void:
	for child in _detail.get_children():
		child.queue_free()
	if _selected.is_empty():
		var empty := Style.make_body("چیزی انتخاب نشده.", Palette.FS_LABEL,
			Palette.SNOW_SOFT)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_detail.add_child(empty)
		return

	var entry: Dictionary = ITEMS.get(_selected, {})
	var head := HBoxContainer.new()
	head.layout_direction = Control.LAYOUT_DIRECTION_RTL
	head.add_theme_constant_override("separation", Palette.PAD_MD)
	_detail.add_child(head)
	head.add_child(Style.make_item_slot(String(entry.get("glyph", "magnifier")),
		0, 104.0))
	var title := Style.make_title(String(entry.get("name", _selected)),
		Palette.FS_HEADING, Palette.SNOW)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)

	_detail.add_child(Style.make_body(String(entry.get("about",
		"چیزی که در راه پیدا کردی.")), Palette.FS_LABEL, Palette.SNOW_SOFT))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(spacer)

	var use := Style.make_button("بررسی", "primary")
	use.pressed.connect(func(): AudioManager.play_sfx("SFX_UI_TAP"))
	_detail.add_child(use)

class _Chosen extends Control:
	## The gold edge the sheet puts on the slot you are looking at.
	func _draw() -> void:
		RazinoUI.glow(get_canvas_item(), Rect2(Vector2.ZERO, size),
			RazinoUI.RADIUS_SLOT, Palette.GOLD_BRIGHT, 0.5)
		var pts := RazinoUI._ring(Rect2(Vector2.ONE, size - Vector2.ONE * 2.0),
			RazinoUI.RADIUS_SLOT)
		pts.append(pts[0])
		CI.polyline(get_canvas_item(), pts, Palette.GOLD_BRIGHT, 2.4)
