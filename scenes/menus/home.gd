extends Control
## UI-04 — صفحهٔ اصلی, in Razino's one 2D language.
##
## An earlier pass drew this screen as embossed metal while the cast were
## flat drawings, and on one screen that read as two games stuck together.
## Everything here is Flat now: outlined shapes, flat fills, hard offset
## shadows, no bevel and no gloss anywhere. The energy comes from contrast
## and chunk, not from shine.
##
## GDD §5 screen 1 still rules the content: within a couple of seconds a
## child must see where they are and where to carry on. So the biggest thing
## on the screen is the chapter they are in and the one button that resumes
## it, and the cast are standing on it — this is their game, and a main
## screen without them on it is a menu, not a front door.

const MENU := [
	{"label": "نقشهٔ جهان", "icon": "compass", "ui": "UI-05"},
	{"label": "فصل‌ها", "icon": "map", "ui": "UI-10"},
	{"label": "کوله‌پشتی", "icon": "backpack", "ui": "UI-19"},
	{"label": "سرنخ‌ها", "icon": "magnifier", "ui": "UI-08"},
	{"label": "فروشگاه", "icon": "box", "ui": "UI-11"},
]

const SECONDARY := [
	{"icon": "friend", "ui": "UI-17", "tip": "پروفایل"},
	{"icon": "bell", "ui": "UI-18", "tip": "اعلان‌ها"},
	{"icon": "star", "ui": "UI-12", "tip": "لباس‌ها"},
	{"icon": "shield", "ui": "UI-14", "tip": "بخش والدین"},
]

const SAFE := 26

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	Style.attach(self)
	_build_backdrop()
	_build_cast()
	_build_top_bar()
	_build_menu()
	_build_hero()
	_build_secondary()

# — backdrop ———————————————————————————————————————————————

func _build_backdrop() -> void:
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	# The plain town, not the start screen's vista: that one has an ornate
	# gold frame painted into it, which is the old style showing through the
	# new one at all four corners.
	var town: Texture2D = null
	for path in ["res://assets/art/backgrounds/ui_town.webp",
			"res://assets/art/backgrounds/ui_splash.webp"]:
		if ResourceLoader.exists(path):
			town = load(path)
			break
	if town != null:
		var art := TextureRect.new()
		art.texture = town
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Knocked back so the flat shapes on top stay the loudest thing on
		# the screen. A painting at full strength and flat graphics over it
		# fight, and the graphics lose.
		art.modulate = Color(0.62, 0.70, 0.78, 1.0)
		add_child(art)

	var veil := _Veil.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

## The cast standing on the main screen, behind the panels. This is the one
## place in the game where all of them are together, and it is what tells a
## child in one glance whose game this is.
func _build_cast() -> void:
	var band := _Cast.new()
	band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)

# — top bar ————————————————————————————————————————————————

func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.layout_direction = Control.LAYOUT_DIRECTION_LTR
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = SAFE
	bar.offset_right = -SAFE
	bar.offset_top = SAFE
	bar.add_theme_constant_override("separation", Palette.PAD_SM)
	add_child(bar)

	bar.add_child(_player_card())

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(gap)

	bar.add_child(_purse("coin", GameState.coins, Palette.GOLD_BRIGHT))
	bar.add_child(_purse("gem", GameState.gems, Palette.BLUE))
	bar.add_child(_disc_button("gear", "تنظیمات", "UI-13", 62.0))

func _player_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		ClayBox.make(ClayBox.Kind.SURFACE, Palette.PANEL, Clay.RADIUS, 12, 10))
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	card.add_child(row)

	var face := _Portrait.new()
	face.art = CastArt.face("player")
	face.custom_minimum_size = Vector2(62, 62)
	row.add_child(face)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(col)

	var line := HBoxContainer.new()
	line.layout_direction = Control.LAYOUT_DIRECTION_RTL
	line.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(line)
	var who := GameState.player_name if not GameState.player_name.is_empty() else "بازیکن"
	line.add_child(Style.make_body(who, Palette.FS_LABEL, Palette.SNOW, false))
	line.add_child(_pill("سطح %s" % Fa.num(GameState.level)))

	var bar := _Meter.new()
	bar.ratio = clampf(float(GameState.xp) / maxf(1.0, float(GameState.xp_for_next_level())), 0.0, 1.0)
	bar.custom_minimum_size = Vector2(190, 16)
	col.add_child(bar)
	return card

func _pill(text: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel",
		ClayBox.make(ClayBox.Kind.SURFACE, Palette.GOLD, Clay.RADIUS_PILL, 12, 3))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(Style.make_body(text, Palette.FS_CAPTION, Palette.NIGHT, false))
	return p

func _purse(icon: String, amount: int, colour: Color) -> Control:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel",
		ClayBox.make(ClayBox.Kind.SURFACE, Palette.PANEL, Clay.RADIUS_PILL, 16, 8))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", Palette.PAD_XS)
	chip.add_child(row)
	var badge := IconRect.new(icon, 32.0, colour)
	badge.painted = false
	row.add_child(badge)
	var n := Style.make_body(Fa.num(amount), Palette.FS_LABEL, Palette.SNOW, false)
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(n)
	return chip

func _disc_button(icon: String, tip: String, ui_id: String,
		side: float) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(side, side)
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var art := _Disc.new()
	art.icon = icon
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	b.pressed.connect(func(): _go(ui_id))
	return b

# — menu ———————————————————————————————————————————————————

func _build_menu() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		ClayBox.make(ClayBox.Kind.SURFACE, Palette.PANEL, Clay.RADIUS, 12, 14))
	panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = SAFE
	panel.offset_right = SAFE + 300
	panel.offset_top = -200
	panel.offset_bottom = 200
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	for i in MENU.size():
		column.add_child(_menu_row(MENU[i], i == 0))

func _menu_row(entry: Dictionary, active: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 66)
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var lit: bool = active or state in ["hover", "focus"]
		if lit or state == "pressed":
			var box := ClayBox.make(ClayBox.Kind.BUTTON, Palette.ACTION if lit else Palette.PANEL_LIGHT, Clay.RADIUS, 12, 6)
			if state == "pressed":
				box = box.as_pressed()
			b.add_theme_stylebox_override(state, box)
		else:
			b.add_theme_stylebox_override(state, StyleBoxEmpty.new())

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_right = -18
	row.offset_bottom = -6
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	var icon := IconRect.new(String(entry["icon"]), 42.0,
		Palette.NIGHT if active else Palette.GOLD_BRIGHT)
	icon.painted = false
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var label := Style.make_body(String(entry["label"]), Palette.FS_HEADING,
		Palette.SNOW, false)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var ui_id := String(entry["ui"])
	b.pressed.connect(func(): _go(ui_id))
	return b

# — hero ———————————————————————————————————————————————————

func _build_hero() -> void:
	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel",
		ClayBox.make(ClayBox.Kind.SURFACE, Palette.PANEL, Clay.RADIUS, 20, 16))
	hero.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hero.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hero.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hero.offset_left = SAFE + 316
	hero.offset_right = -SAFE
	hero.offset_bottom = -SAFE
	add_child(hero)

	var inside := HBoxContainer.new()
	inside.layout_direction = Control.LAYOUT_DIRECTION_RTL
	inside.add_theme_constant_override("separation", Palette.PAD_MD)
	hero.add_child(inside)

	var col := VBoxContainer.new()
	col.layout_direction = Control.LAYOUT_DIRECTION_RTL
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", Palette.PAD_SM)
	inside.add_child(col)

	var head := HBoxContainer.new()
	head.layout_direction = Control.LAYOUT_DIRECTION_RTL
	head.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(head)

	var plaque := PanelContainer.new()
	plaque.add_theme_stylebox_override("panel",
		ClayBox.make(ClayBox.Kind.PLAQUE, Palette.GOLD_BRIGHT, Clay.RADIUS, 24, 5))
	plaque.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plaque.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ch := Style.make_title("فصل اول", Palette.FS_LABEL, Palette.NIGHT)
	ch.autowrap_mode = TextServer.AUTOWRAP_OFF
	plaque.add_child(ch)
	head.add_child(plaque)

	var entry := _current_chapter()
	var title := Style.make_title(String(entry.get("title", "راز ساعت خاموش")),
		Palette.FS_TITLE, Palette.SNOW)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)

	var done := _chapter_progress()
	var meter := _Meter.new()
	meter.ratio = done
	meter.custom_minimum_size = Vector2(0, 18)
	col.add_child(meter)
	col.add_child(Style.make_body(
		"%s از مرحله‌های این فصل تمام شده." % Fa.percent(done),
		Palette.FS_CAPTION, Palette.SNOW_SOFT))

	var go := Button.new()
	go.text = "ادامهٔ بازی"
	go.custom_minimum_size = Vector2(0, 86)
	go.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "focus", "disabled"]:
		go.add_theme_stylebox_override(state,
			ClayBox.make(ClayBox.Kind.BUTTON, Palette.ACTION, Clay.RADIUS, 20, 14))
	go.add_theme_stylebox_override("pressed",
		ClayBox.make(ClayBox.Kind.BUTTON, Palette.ACTION, Clay.RADIUS, 20, 14).as_pressed())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		go.add_theme_color_override(key, Palette.SNOW)
	go.add_theme_font_size_override("font_size", Style.scaled(Palette.FS_HEADING))
	go.pressed.connect(func(): _go("UI-20", {"chapter_id": _chapter_id()}))
	col.add_child(go)

	var tile := _Tile.new()
	tile.custom_minimum_size = Vector2(176, 158)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.art = SceneArt.load_texture("BG_S01_CLOCK_TOWER", _chapter_id())
	inside.add_child(tile)

func _build_secondary() -> void:
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_left = SAFE
	row.offset_bottom = -SAFE
	row.add_theme_constant_override("separation", Palette.PAD_XS)
	add_child(row)
	for entry: Dictionary in SECONDARY:
		row.add_child(_disc_button(String(entry["icon"]), String(entry["tip"]),
			String(entry["ui"]), 54.0))

# — content ————————————————————————————————————————————————

func _chapter_id() -> String:
	var id := GameState.current_chapter
	return id if not id.is_empty() else "season_01"

func _current_chapter() -> Dictionary:
	for entry in ContentManager.catalog:
		if String((entry as Dictionary).get("chapter_id", "")) == _chapter_id():
			return entry
	return {}

func _chapter_progress() -> float:
	var stages: Array = StageEngine.stages
	if stages.is_empty():
		return 0.0
	var done := 0
	for s: Dictionary in stages:
		if GameState.is_stage_complete(String(s.get("stage_id", ""))):
			done += 1
	return float(done) / float(stages.size())

func _go(ui_id: String, payload: Dictionary = {}) -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	Router.go(ui_id, payload)

# — drawn pieces ——————————————————————————————————————————

class _Veil extends Control:
	func _draw() -> void:
		var ci := get_canvas_item()
		# One flat wash plus one flat band along the bottom, where the hero
		# panel sits. Flat, not a ramp — a soft vignette under hard-edged
		# shapes is the tell that two styles are in play.
		CI.rect(ci, Rect2(Vector2.ZERO, size),
			Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, 0.34))
		CI.rect(ci, Rect2(0, size.y * 0.52, size.x, size.y * 0.48),
			Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, 0.30))

class _Cast extends Control:
	func _draw() -> void:
		# Standing along the bottom, largest in the middle, all of them
		# cropped by the hero panel that sits over them — which is why they
		# are drawn from the feet up rather than centred.
		# They stand on the top edge of the hero panel, not on the bottom of
		# the window. Standing on the window put everyone but their heads
		# behind the panel, which is the opposite of the point of having
		# them here.
		var ground := size.y * 0.66
		var who: Array[String] = ["mani", "raha", "arad", "player"]
		var spots: Array[float] = [0.40, 0.54, 0.69, 0.84]
		var heights: Array[float] = [0.40, 0.46, 0.45, 0.39]
		for i in who.size():
			var tex := CastArt.figure(who[i])
			if tex == null:
				continue
			var h: float = size.y * heights[i]
			var w: float = h * tex.get_size().x / tex.get_size().y
			draw_texture_rect(tex, Rect2(
				Vector2(size.x * spots[i] - w * 0.5, ground - h),
				Vector2(w, h)), false)

class _Portrait extends Control:
	var art: Texture2D = null
	func _draw() -> void:
		var ci := get_canvas_item()
		var centre := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		Clay.disc(ci, centre, r, Palette.PANEL_LIGHT)
		if art != null:
			var box := Rect2(centre - Vector2(r, r) * 0.88, Vector2(r, r) * 1.76)
			draw_texture_rect(art, box, false)


class _Disc extends Control:
	var icon: String = "gear"
	func _draw() -> void:
		var ci := get_canvas_item()
		var centre := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		Clay.disc(ci, centre, r, Palette.PANEL)
		# Outlined like every other shape in this style. A solid gold glyph
		# at 54 pixels with nothing around it reads as a blob.
		GameIcons.draw(ci, icon, centre, r * 0.50, Palette.GOLD_BRIGHT)

class _Meter extends Control:
	var ratio: float = 0.0
	func _draw() -> void:
		Clay.meter(get_canvas_item(), Rect2(Vector2.ZERO, size), ratio)

class _Tile extends Control:
	var art: Texture2D = null
	func _draw() -> void:
		var ci := get_canvas_item()
		var r := Rect2(Vector2.ZERO, size)
		Clay.well(ci, r, Clay.RADIUS, Palette.NIGHT)
		if art != null:
			var inner := r.grow(-8.0)
			draw_texture_rect(art, inner, false)

