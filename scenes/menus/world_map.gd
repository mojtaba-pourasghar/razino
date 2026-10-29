extends Control
## UI-05 — نقشهٔ جهان, laid out as the approved panel sheet draws it
## (assets/art/reference/panels_sheet.jpg, top right).
##
## A side menu in its own panel with the current page in gold, and beside it
## the map in a framed window: a bare painting of the islands
## (content_tools/paint_worldmap.py) with a small navy plaque floating over
## each one and the purse in the corner. Nothing on the map is painted
## writing, so every name is a real chapter title and every state is live.

const MAP := "res://assets/art/backgrounds/worldmap_clean.webp"

## Where each island's plaque sits, as a fraction of the painting, in the
## order the chapters fill them: the castle town in the middle first, then
## round the ring.
const ISLANDS := [
	Vector2(0.49, 0.55),
	Vector2(0.21, 0.31),
	Vector2(0.51, 0.18),
	Vector2(0.80, 0.33),
	Vector2(0.79, 0.76),
	Vector2(0.49, 0.90),
	Vector2(0.22, 0.79),
]

## The side menu, top to bottom. The first is this page.
const MENU := [
	{"label": "جهان", "icon": "globe", "ui": ""},
	{"label": "مأموریت‌ها", "icon": "star", "ui": "UI-20"},
	{"label": "دفترچهٔ سرنخ‌ها", "icon": "book", "ui": "UI-08"},
	{"label": "تنظیمات", "icon": "gear", "ui": "UI-13"},
]

var _map: TextureRect
var _plaques: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Laid out as a picture, left to right; every text inside is RTL itself.
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	Style.attach(self)
	_build()

func _build() -> void:
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(night)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_top = 18
	row.offset_right = -18
	row.offset_bottom = -18
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	row.add_child(_side_menu())
	row.add_child(_map_window())

# — the side menu ——————————————————————————————————————————

func _side_menu() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 230
	panel.add_theme_stylebox_override("panel", UiBox.make(UiBox.Kind.PANEL, 16, 22))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var title := Style.make_title("نقشهٔ جهان", Palette.FS_HEADING, Palette.GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var rule := ColorRect.new()
	rule.color = Palette.GOLD_DEEP
	rule.custom_minimum_size.y = 1
	col.add_child(rule)

	for i in MENU.size():
		col.add_child(_menu_button(MENU[i], i == 0))

	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(gap)
	col.add_child(_menu_button({"label": "بازگشت", "icon": "home", "ui": "UI-04"}, false))
	return panel

func _menu_button(entry: Dictionary, here: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, RazinoUI.TOUCH_MIN + 4)
	b.focus_mode = Control.FOCUS_ALL
	var box := UiBox.make(UiBox.Kind.PRIMARY if here else UiBox.Kind.BUTTON, 14, 6)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", box.state(false, true))
	b.add_theme_stylebox_override("focus", box.state(false, true))
	b.add_theme_stylebox_override("pressed", box.state(true, false))
	var ink := Palette.INK if here else Palette.SNOW

	var inner := HBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 14
	inner.offset_right = -14
	inner.layout_direction = Control.LAYOUT_DIRECTION_RTL
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(inner)
	var icon := IconRect.new(String(entry["icon"]), 22.0, ink)
	icon.painted = false
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.add_child(icon)
	var label := Style.make_body(String(entry["label"]), Palette.FS_LABEL, ink, false)
	if Style.font_bold != null:
		label.add_theme_font_override("font", Style.font_bold)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Alignment is left to Style, which gives every label its own right-to-
	# left direction; setting RIGHT here flipped this one back to the far
	# edge of the row, away from its icon.
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	inner.add_child(label)

	var ui_id := String(entry["ui"])
	if here:
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		b.pressed.connect(func():
			AudioManager.play_sfx("SFX_UI_TAP")
			Router.go(ui_id, {"chapter_id": _current_chapter()}))
	return b

# — the map ——————————————————————————————————————————————

func _map_window() -> Control:
	var window := PanelContainer.new()
	window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window.add_theme_stylebox_override("panel", UiBox.make(UiBox.Kind.PANEL, 10, 10))

	var room := Control.new()
	room.clip_contents = true
	window.add_child(room)

	_map = TextureRect.new()
	_map.texture = load(MAP) if ResourceLoader.exists(MAP) else null
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(_map)

	var chapters := ContentManager.chapter_ids()
	var current := _current_chapter()
	for i in mini(ISLANDS.size(), chapters.size()):
		var chapter_id := String(chapters[i])
		var plaque := _plaque(chapter_id, chapter_id == current)
		room.add_child(plaque)
		_plaques.append({"node": plaque, "at": ISLANDS[i]})

	var purse := HBoxContainer.new()
	purse.add_theme_constant_override("separation", 8)
	purse.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	purse.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	purse.offset_top = 10
	purse.offset_right = -12
	purse.add_child(Style.make_chip("gem", GameState.gems, Palette.BLUE))
	purse.add_child(Style.make_chip("coin", GameState.coins, Palette.GOLD_BRIGHT))
	room.add_child(purse)

	room.resized.connect(func(): _place_plaques(room.size))
	return window

## A plaque over an island: the chapter's name, and under it where the
## player stands in it. The chapter they are in is gold.
func _plaque(chapter_id: String, here: bool) -> Button:
	var entry := ContentManager.catalog_entry(chapter_id)
	var open := GameState.is_chapter_unlocked(chapter_id)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.disabled = not open
	var box := UiBox.make(UiBox.Kind.PRIMARY if here else UiBox.Kind.BUTTON, 14, 6)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", box.state(false, true))
	b.add_theme_stylebox_override("focus", box.state(false, true))
	b.add_theme_stylebox_override("pressed", box.state(true, false))
	b.add_theme_stylebox_override("disabled", box)

	var ink := Palette.INK if here else Palette.SNOW
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", -2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)

	var name := Style.make_body(String(entry.get("title", chapter_id)),
		Palette.FS_CAPTION, ink, false)
	if Style.font_bold != null:
		name.add_theme_font_override("font", Style.font_bold)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(name)

	var state := HBoxContainer.new()
	state.alignment = BoxContainer.ALIGNMENT_CENTER
	state.add_theme_constant_override("separation", 4)
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(state)
	if not open:
		var lock := IconRect.new("lock", 14.0, Palette.GOLD_BRIGHT)
		lock.painted = false
		lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		state.add_child(lock)
	var line := Style.make_body(_state_of(chapter_id, open), Palette.FS_CAPTION - 2,
		ink if here else Palette.GOLD_LIGHT, false)
	state.add_child(line)

	b.custom_minimum_size = Vector2(170, 58)
	b.pressed.connect(func():
		AudioManager.play_sfx("SFX_UI_TAP")
		Router.go("UI-10", {"chapter_id": chapter_id}))
	return b

## The painting is drawn covering its window, so a fraction of the painting
## is not a fraction of the window: it is mapped through the same scale and
## crop the TextureRect used.
func _place_plaques(area: Vector2) -> void:
	if _map.texture == null:
		return
	var art := _map.texture.get_size()
	var k := maxf(area.x / art.x, area.y / art.y)
	var origin := (area - art * k) * 0.5
	for entry: Dictionary in _plaques:
		var plaque: Control = entry["node"]
		var at: Vector2 = origin + (entry["at"] as Vector2) * art * k
		var s := plaque.custom_minimum_size
		var pos := at - s * 0.5
		pos.x = clampf(pos.x, 6.0, area.x - s.x - 6.0)
		pos.y = clampf(pos.y, 6.0, area.y - s.y - 6.0)
		plaque.position = pos
		plaque.size = s

func _current_chapter() -> String:
	var id := GameState.current_chapter
	return id if not id.is_empty() else "season_01"

## What the second line of a plaque says. A chapter the player is part way
## through says so, because "باز" on a chapter half finished tells them
## nothing they did not know.
func _state_of(chapter_id: String, open: bool) -> String:
	if not open:
		return "قفل"
	if GameState.is_chapter_complete(chapter_id):
		return "تمام شد"
	var entry := ContentManager.catalog_entry(chapter_id)
	var percent := GameState.chapter_percent(chapter_id, int(entry.get("scene_count", 1)))
	if percent > 0.0:
		return Fa.percent(percent)
	return "باز"
