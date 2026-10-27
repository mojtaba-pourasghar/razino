extends Control
## UI-04 — صفحهٔ اصلی, rebuilt in the language of the approved sheets.
##
## The first version of this screen was a painted town with flat pills laid
## over it, and it read as a generic dark theme — the thing that made the
## sheets look expensive was missing from it entirely: the dark navy panels
## with gold hairlines and corner brackets, the ivy over the outer frame, the
## petrol-teal call to action lit from above, the soft glow behind anything
## valuable. All of that is drawn here through Filigree.
##
## GDD §5 screen 1 still rules the content: within a couple of seconds a
## child must see where they are and where to carry on. So the largest thing
## on the screen is the chapter they are in and the one button that resumes
## it; everything else is smaller and to the side.

const MENU := [
	{"label": "نقشهٔ جهان", "icon": "compass", "ui": "UI-05"},
	{"label": "فصل‌ها", "icon": "map", "ui": "UI-10"},
	{"label": "کوله‌پشتی", "icon": "backpack", "ui": "UI-19"},
	{"label": "سرنخ‌ها", "icon": "magnifier", "ui": "UI-08"},
	{"label": "فروشگاه", "icon": "box", "ui": "UI-11"},
]

## Kept off the child's main path, as the sheets keep them: small medallions
## in the corner rather than another column of buttons.
const SECONDARY := [
	{"icon": "friend", "ui": "UI-17", "tip": "پروفایل"},
	{"icon": "bell", "ui": "UI-18", "tip": "اعلان‌ها"},
	{"icon": "star", "ui": "UI-12", "tip": "لباس‌ها"},
	{"icon": "download", "ui": "UI-15", "tip": "دانلودها"},
	{"icon": "shield", "ui": "UI-14", "tip": "بخش والدین"},
]

const SAFE := 30

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	Style.attach(self)
	_build_backdrop()
	_build_top_bar()
	_build_menu()
	_build_hero()
	_build_secondary()

# — the painting behind everything ————————————————————————

func _build_backdrop() -> void:
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	var town := UiArt.plate("splash_vista")
	if town == null and ResourceLoader.exists("res://assets/art/backgrounds/ui_town.webp"):
		town = load("res://assets/art/backgrounds/ui_town.webp")
	if town != null:
		var art := TextureRect.new()
		art.texture = town
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)

	# A vignette rather than a flat wash. The sheets keep the middle of the
	# picture bright and darken the edges, which is what lets white Persian
	# text sit on the corners and the town still read as daylight.
	var veil := _Vignette.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var frame := _Frame.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

# — top bar ————————————————————————————————————————————————

func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	# The sheets fix this order — player left, purse right — and it is part
	# of the design, not a consequence of reading direction.
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
	var gear := Medallion.new("gear", 58.0)
	gear.tooltip_text = "تنظیمات"
	gear.pressed.connect(func(): _go("UI-13"))
	bar.add_child(gear)

## The player, as the profile sheet draws them: portrait in a gold ring, name
## on a plaque, level and the experience bar under it.
func _player_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		FiligreeBox.make(FiligreeBox.Kind.PANEL, 20.0, 14, 10))
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	card.add_child(row)

	var face := Medallion.new("friend", 62.0, false)
	face.portrait = CastArt.figure("player")
	row.add_child(face)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(col)

	var name_row := HBoxContainer.new()
	name_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	name_row.add_theme_constant_override("separation", Palette.PAD_XS)
	col.add_child(name_row)
	var who := GameState.player_name if not GameState.player_name.is_empty() else "بازیکن"
	name_row.add_child(Style.make_body(who, Palette.FS_LABEL, Palette.SNOW, false))
	name_row.add_child(Style.make_body("سطح %s" % Fa.num(GameState.level),
		Palette.FS_CAPTION, Palette.GOLD_BRIGHT, false))

	var bar := _Meter.new()
	bar.ratio = clampf(float(GameState.xp) / maxf(1.0, float(GameState.xp_for_next_level())), 0.0, 1.0)
	bar.custom_minimum_size = Vector2(196, 13)
	col.add_child(bar)
	return card

func _purse(icon: String, amount: int, colour: Color) -> Control:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel",
		FiligreeBox.make(FiligreeBox.Kind.PANEL, 999.0, 16, 7))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", Palette.PAD_XS)
	chip.add_child(row)
	var badge := _GlowIcon.new()
	badge.icon = icon
	badge.colour = colour
	badge.custom_minimum_size = Vector2(34, 34)
	row.add_child(badge)
	var n := Style.make_body(Fa.num(amount), Palette.FS_LABEL, Palette.SNOW, false)
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(n)
	return chip

# — the menu column ————————————————————————————————————————

func _build_menu() -> void:
	var column := VBoxContainer.new()
	# Anchored by hand, so RTL must not mirror it: the sheets put the menu on
	# the left and the chapter on the right, and that is the composition, not
	# a consequence of reading direction. The Persian inside each row is
	# still laid out right to left.
	column.layout_direction = Control.LAYOUT_DIRECTION_LTR
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	column.offset_left = SAFE
	column.offset_right = SAFE + 290
	column.offset_top = -190
	column.offset_bottom = 190
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	for entry: Dictionary in MENU:
		column.add_child(_menu_button(entry))

## One menu row: an icon in a gold ring, the Persian label beside it, on a
## navy panel with a hairline and brackets. The sheets never put a label on
## bare art, and this is why — a gold-edged plate is what makes it tappable.
func _menu_button(entry: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 62)
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := FiligreeBox.make(FiligreeBox.Kind.PANEL, 16.0, 12, 8)
		box.fill = Palette.PANEL if state == "hover" else Palette.PANEL_DEEP
		b.add_theme_stylebox_override(state, box)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	var medal := Medallion.new(String(entry["icon"]), 44.0, false)
	medal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(medal)

	var label := Style.make_body(String(entry["label"]), Palette.FS_LABEL,
		Palette.SNOW, false)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var ui_id := String(entry["ui"])
	b.pressed.connect(func(): _go(ui_id))
	return b

# — the hero: where the child carries on ——————————————————

func _build_hero() -> void:
	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel",
		FiligreeBox.make(FiligreeBox.Kind.PANEL, 24.0, 22, 16))
	hero.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hero.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hero.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hero.offset_left = SAFE + 320
	hero.offset_right = -SAFE
	hero.offset_bottom = -SAFE
	add_child(hero)

	# Picture on one side, words on the other: an empty dark panel is the
	# thing that made the first pass look cheap, and the sheets never leave
	# one.
	var inside := HBoxContainer.new()
	inside.layout_direction = Control.LAYOUT_DIRECTION_RTL
	inside.add_theme_constant_override("separation", Palette.PAD_MD)
	hero.add_child(inside)

	var col := VBoxContainer.new()
	col.layout_direction = Control.LAYOUT_DIRECTION_RTL
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", Palette.PAD_SM)
	inside.add_child(col)

	var entry := _current_chapter()
	var head := HBoxContainer.new()
	head.layout_direction = Control.LAYOUT_DIRECTION_RTL
	head.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(head)

	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel",
		FiligreeBox.make(FiligreeBox.Kind.PLAQUE, 0.0, 26, 6))
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var plate_text := Style.make_title("فصل اول", Palette.FS_LABEL, Palette.GOLD_BRIGHT)
	# Between two things that want the row's width, a wrapping label shrinks
	# to one glyph per line — the plaque came out as a vertical stack of
	# letters.
	plate_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	plate.add_child(plate_text)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.add_child(plate)

	var title := Style.make_title(String(entry.get("title", "راز ساعت خاموش")),
		Palette.FS_TITLE, Palette.SNOW)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)

	var done := _chapter_progress()
	var meter := _Meter.new()
	meter.ratio = done
	meter.custom_minimum_size = Vector2(0, 15)
	col.add_child(meter)

	var line := Style.make_body(
		"%s از مرحله‌های این فصل تمام شده." % Fa.percent(done),
		Palette.FS_CAPTION, Palette.SNOW_SOFT)
	col.add_child(line)

	inside.add_child(_chapter_tile())

	var go := Button.new()
	go.text = "ادامهٔ بازی"
	go.custom_minimum_size = Vector2(0, 68)
	go.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "focus", "disabled"]:
		go.add_theme_stylebox_override(state,
			FiligreeBox.make(FiligreeBox.Kind.ACTION, 18.0, 20, 12))
	go.add_theme_stylebox_override("pressed",
		(FiligreeBox.make(FiligreeBox.Kind.ACTION, 18.0, 20, 12) as FiligreeBox).as_pressed())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		go.add_theme_color_override(key, Palette.SNOW)
	go.add_theme_font_size_override("font_size", Style.scaled(Palette.FS_HEADING))
	go.pressed.connect(func(): _go("UI-20", {"chapter_id": _chapter_id()}))
	col.add_child(go)

## The chapter's own painting in a gold-edged tile, with the fox leaning on
## it. The tile is what gives the panel something to look at; the fox is what
## makes it this game's panel and not any game's panel.
func _chapter_tile() -> Control:
	var tile := _Tile.new()
	tile.custom_minimum_size = Vector2(190, 150)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.art = SceneArt.load_texture("BG_S01_CLOCK_TOWER", _chapter_id())
	tile.figure = CastArt.figure("fandogh")
	return tile

func _build_secondary() -> void:
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_left = SAFE
	# Clear of the chapter panel, which starts at SAFE + 320 on this edge.
	row.offset_bottom = -SAFE
	row.add_theme_constant_override("separation", Palette.PAD_XS)
	add_child(row)
	for entry: Dictionary in SECONDARY:
		var m := Medallion.new(String(entry["icon"]), 50.0)
		m.tooltip_text = String(entry["tip"])
		var ui_id := String(entry["ui"])
		m.pressed.connect(func(): _go(ui_id))
		row.add_child(m)

# — content ————————————————————————————————————————————————

func _chapter_id() -> String:
	var id := GameState.current_chapter
	return id if not id.is_empty() else "season_01"

func _current_chapter() -> Dictionary:
	for entry in ContentManager.catalog:
		if String((entry as Dictionary).get("chapter_id", "")) == _chapter_id():
			return entry
	return {}

## How much of the current chapter is behind the player, by stages finished.
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

# — small drawn pieces ————————————————————————————————————

class _Frame extends Control:
	func _draw() -> void:
		Filigree.window_frame(get_canvas_item(), Rect2(Vector2.ZERO, size))

class _Vignette extends Control:
	func _draw() -> void:
		var ci := get_canvas_item()
		var bands := 22
		var depth := minf(size.x, size.y) * 0.42
		for i in bands:
			var t := float(i) / float(bands - 1)
			var inset := depth * t
			var a := 0.5 * (1.0 - t) * (1.0 - t)
			# Four edge strips rather than a ring, so the middle of the
			# picture is never touched.
			CI.rect(ci, Rect2(0, inset, size.x, depth / bands + 1.0),
				Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, a))
			CI.rect(ci, Rect2(0, size.y - inset - depth / bands, size.x, depth / bands + 1.0),
				Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, a))
			CI.rect(ci, Rect2(inset, 0, depth / bands + 1.0, size.y),
				Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, a * 0.9))
			CI.rect(ci, Rect2(size.x - inset - depth / bands, 0, depth / bands + 1.0, size.y),
				Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, a * 0.9))

class _Tile extends Control:
	var art: Texture2D = null
	var figure: Texture2D = null
	func _draw() -> void:
		var ci := get_canvas_item()
		var r := Rect2(Vector2.ZERO, size)
		Filigree.panel(ci, r, 14.0, Palette.NIGHT)
		if art != null:
			# Inset so the painting sits inside the metal rather than under
			# it, which is how every framed picture in the sheets is set.
			var inner := r.grow(-7.0)
			draw_texture_rect(art, inner, false)
			Filigree.outline(ci, inner, 9.0, Palette.GOLD_DEEP, 1.4)
		if figure != null:
			var h := size.y * 0.78
			var w := h * figure.get_size().x / figure.get_size().y
			draw_texture_rect(figure,
				Rect2(Vector2(-w * 0.28, size.y - h), Vector2(w, h)), false)

class _Meter extends Control:
	var ratio: float = 0.0
	func _draw() -> void:
		var ci := get_canvas_item()
		var r := Rect2(Vector2.ZERO, size)
		var radius := size.y * 0.5
		Filigree.outline(ci, r, radius, Palette.GOLD_DEEP, 3.0)
		CI.poly(ci, Filigree._ring(r.grow(-2.0), radius), Palette.NIGHT)
		if ratio <= 0.0:
			return
		var filled := r.grow(-3.0)
		filled.size.x *= clampf(ratio, 0.0, 1.0)
		if filled.size.x < filled.size.y:
			filled.size.x = filled.size.y
		# One rounded body, then a lit band inside the top edge. Drawing the
		# gradient as a row of rounded segments turned the bar into a string
		# of beads: each segment was narrower than its own corner radius.
		CI.poly(ci, Filigree._ring(filled, minf(radius, filled.size.y * 0.5)),
			Palette.ACTION_LIGHT)
		var lit := filled.grow(-2.0)
		lit.size.y *= 0.45
		if lit.size.x > 2.0 and lit.size.y > 1.0:
			CI.poly(ci, Filigree._ring(lit, minf(radius, lit.size.y * 0.5)),
				Palette.ACTION_LIGHT.lerp(Palette.PARCHMENT, 0.55))
		Filigree.outline(ci, r, radius, Palette.GOLD_BRIGHT, 1.6)

class _GlowIcon extends Control:
	var icon: String = "coin"
	var colour: Color = Palette.GOLD_BRIGHT
	func _draw() -> void:
		var ci := get_canvas_item()
		var centre := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		Filigree.glow(ci, centre, r * 1.5, colour)
		var painted := UiArt.icon(icon)
		if painted != null:
			var side := r * 1.9
			draw_texture_rect(painted,
				Rect2(centre - Vector2(side, side) * 0.5, Vector2(side, side)), false)
		else:
			GameIcons.draw(ci, icon, centre, r * 0.9, colour)
