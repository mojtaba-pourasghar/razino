extends Control
## UI-01 — the start screen.
##
## Every piece is its own painting on transparent ground (see
## content_tools/paint_splash.py): the town, the cast, the crest and the
## plates. They are layered here rather than flattened into one picture, so
## each can come in on its own and keep a little life once it has — the town
## drifts, the crest floats, the cast breathes, motes of light rise. All of
## that stops when the player has asked for reduced motion.
##
## The composition reads from right to left, as a Persian page does: the
## name, the button and the side actions sit together on the right, where
## the eye lands first, and the cast stands on the left looking on. The
## anchors below are written as if for a left-to-right page; the screen is
## RTL, so Godot mirrors every one of them.
##
## It is also the one place that decides where a returning player lands:
## straight back into their chapter if they have progress, the intro if they
## do not. The warm-up runs while the player is still looking at the
## picture, so the button is live by the time they reach for it.

const ART := "res://assets/art/splash/"

const SIDE_ACTIONS := [
	{"icon": "gear", "label": "تنظیمات", "ui": "UI-13"},
	{"icon": "friend", "label": "پروفایل", "ui": "UI-17"},
	{"icon": "book", "label": "راهنما", "ui": "UI-02"},
]

## Where the title is written on the crest, as a fraction of the crest
## painting: the empty navy field of its plaque.
const PLAQUE := Rect2(0.17, 0.57, 0.66, 0.30)

## Text on the gold button: dark enough to read on amber, warm enough not to
## look printed.
const INK := Color("3A1E06")

var _start: Button
var _status: Label
var _ready_to_play: bool = false

var _backdrop: TextureRect
var _crest: Control
var _cast: TextureRect
var _left: Control
var _calm: bool = false

func _ready() -> void:
	Log.info("Boot", "starting")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	_calm = Settings.reduce_motion
	Style.attach(self)
	_build()
	resized.connect(_recentre)
	await get_tree().process_frame
	_recentre()
	_enter()
	await _warm_up()

func _build() -> void:
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	# — the town —
	_backdrop = _picture("splash_bg.webp", TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	# Two washes: one up from the floor so the cast's feet and the side
	# actions sit on shade rather than bright grass, one in from the right so
	# the button and its caption read against the town behind them. (A
	# texture is not mirrored by RTL, so this one says "right" itself.)
	add_child(_wash(true, 0.55, 0.45))
	add_child(_wash(false, 0.45, 0.55))

	# — the cast (mirrored to the left) —
	_cast = _picture("splash_cast.png", TextureRect.STRETCH_KEEP_ASPECT)
	_cast.anchor_left = 0.44
	_cast.anchor_right = 1.0
	_cast.anchor_top = 0.20
	_cast.anchor_bottom = 1.0
	_cast.offset_bottom = -6
	add_child(_cast)

	if not _calm:
		add_child(_motes())

	# — the name, the button and the side actions (mirrored to the right) —
	_left = Control.new()
	_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left.anchor_left = 0.03
	_left.anchor_right = 0.50
	_left.anchor_top = 0.0
	_left.anchor_bottom = 1.0
	add_child(_left)

	_crest = _Crest.new()
	_crest.texture = _texture("splash_emblem.png")
	_crest.title = "رازینو"
	_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crest.anchor_right = 1.0
	_crest.anchor_top = 0.04
	_crest.anchor_bottom = 0.44
	_left.add_child(_crest)

	var tagline := Style.make_title("رازِ هر گوشه، ماجرایی تازه", Palette.FS_HEADING,
		Palette.GOLD_LIGHT)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	tagline.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.0, 0.9))
	tagline.add_theme_constant_override("outline_size", 8)
	tagline.anchor_right = 1.0
	tagline.anchor_top = 0.45
	tagline.anchor_bottom = 0.52
	_left.add_child(tagline)

	var middle := VBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 6)
	middle.anchor_right = 1.0
	middle.anchor_top = 0.54
	middle.anchor_bottom = 0.76
	_left.add_child(middle)

	_start = _plate_button("شروع بازی", "button_gold.png", INK)
	_start.custom_minimum_size = Vector2(430, 96)
	_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start.disabled = true
	_start.pressed.connect(_play)
	middle.add_child(_start)

	_status = Style.make_body("در حال آماده‌سازی…", Palette.FS_CAPTION, Palette.SNOW)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_status.add_theme_constant_override("outline_size", 6)
	middle.add_child(_status)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	row.anchor_right = 1.0
	row.anchor_top = 0.77
	row.anchor_bottom = 0.98
	_left.add_child(row)
	for action in SIDE_ACTIONS:
		row.add_child(_side_action(action))

	var version := Style.make_body("v%s" % ProjectSettings.get_setting(
		"application/config/version", "0.1.0"), Palette.FS_CAPTION,
		Palette.SNOW_SOFT, false)
	version.layout_direction = Control.LAYOUT_DIRECTION_LTR
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -90
	version.offset_top = -30
	version.offset_right = -14
	version.offset_bottom = -8
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

# — pieces ————————————————————————————————————————————————

func _texture(file: String) -> Texture2D:
	var path := ART + file
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _picture(file: String, stretch: TextureRect.StretchMode) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _texture(file)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = stretch
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## A wash of night: up from the floor when `from_floor`, otherwise in from
## the right edge. `strength` is its alpha at the edge it starts from;
## `reach` is how far across the screen it has faded to nothing.
func _wash(from_floor: bool, strength: float, reach: float) -> TextureRect:
	var dark := Palette.NIGHT
	dark.a = strength
	var clear := Palette.NIGHT
	clear.a = 0.0
	var g := Gradient.new()
	g.set_color(0, dark)
	g.set_color(1, clear)
	g.set_offset(1, reach)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 1.0) if from_floor else Vector2(1.0, 0.5)
	tex.fill_to = Vector2(0.5, 0.0) if from_floor else Vector2(0.0, 0.5)
	tex.width = 64
	tex.height = 64
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## A button drawn on a painted plate. The plate is cut at the height it is
## drawn at, so only its rounded ends are kept and the middle stretches.
func _plate_button(text: String, plate: String, ink: Color) -> Button:
	var tex := _texture(plate)
	if tex == null:
		return Style.make_button(text)
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	var base := StyleBoxTexture.new()
	base.texture = tex
	base.texture_margin_left = 64
	base.texture_margin_right = 64
	base.content_margin_bottom = 8
	var lit := base.duplicate() as StyleBoxTexture
	lit.modulate_color = Color(1.12, 1.08, 1.0)
	var down := base.duplicate() as StyleBoxTexture
	down.modulate_color = Color(0.82, 0.78, 0.72)
	down.content_margin_top = 4
	var off := base.duplicate() as StyleBoxTexture
	off.modulate_color = Color(0.7, 0.7, 0.7, 0.85)
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("hover", lit)
	b.add_theme_stylebox_override("focus", lit)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("disabled", off)
	if Style.font_bold != null:
		b.add_theme_font_override("font", Style.font_bold)
	b.add_theme_font_size_override("font_size", Style.scaled(Palette.FS_TITLE + 2))
	for state in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		b.add_theme_color_override(state, ink)
	b.add_theme_color_override("font_disabled_color", ink.lerp(Color.GRAY, 0.4))
	b.add_theme_color_override("font_outline_color", Color(1.0, 0.9, 0.6, 0.55))
	b.add_theme_constant_override("outline_size", 3)
	return b

func _side_action(action: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)

	var medal := Button.new()
	medal.custom_minimum_size = Vector2(80, 77)
	medal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	medal.tooltip_text = String(action["label"])
	var face := _texture("medallion.png")
	if face != null:
		var box := StyleBoxTexture.new()
		box.texture = face
		box.set_content_margin_all(15)
		var lit := box.duplicate() as StyleBoxTexture
		lit.modulate_color = Color(1.15, 1.1, 1.0)
		var down := box.duplicate() as StyleBoxTexture
		down.modulate_color = Color(0.8, 0.78, 0.74)
		medal.add_theme_stylebox_override("normal", box)
		medal.add_theme_stylebox_override("hover", lit)
		medal.add_theme_stylebox_override("focus", lit)
		medal.add_theme_stylebox_override("pressed", down)
	medal.icon = UiArt.icon(String(action["icon"]))
	medal.expand_icon = true
	medal.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medal.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	var ui_id := String(action["ui"])
	medal.pressed.connect(func():
		if not _ready_to_play:
			return
		AudioManager.play_sfx("SFX_UI_TAP")
		Router.go(ui_id))
	col.add_child(medal)

	var label := Style.make_body(String(action["label"]), Palette.FS_CAPTION, Palette.SNOW, false)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	col.add_child(label)
	return col

## Specks of warm light drifting up out of the meadow.
func _motes() -> CPUParticles2D:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.92, 0.6, 1.0))
	g.set_color(1, Color(1.0, 0.8, 0.3, 0.0))
	var dot := GradientTexture2D.new()
	dot.gradient = g
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	dot.width = 16
	dot.height = 16

	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 0.9))
	fade.add_point(0.8, Color(1, 1, 1, 0.6))

	var p := CPUParticles2D.new()
	p.name = "Motes"
	p.texture = dot
	p.amount = 36
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 30.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 1.0
	p.color_ramp = fade
	return p

# — layout and motion —————————————————————————————————————

func _recentre() -> void:
	_backdrop.pivot_offset = _backdrop.size * 0.5
	_cast.pivot_offset = Vector2(_cast.size.x * 0.5, _cast.size.y)
	_start.pivot_offset = _start.size * 0.5
	var motes := get_node_or_null("Motes") as CPUParticles2D
	if motes != null:
		motes.position = Vector2(size.x * 0.5, size.y * 0.92)
		motes.emission_rect_extents = Vector2(size.x * 0.5, size.y * 0.06)

func _enter() -> void:
	if _calm:
		return
	var crest_at := _crest.position
	var cast_at := _cast.position
	_backdrop.modulate.a = 0.0
	_crest.modulate.a = 0.0
	_crest.position = crest_at - Vector2(0, 40)
	_cast.modulate.a = 0.0
	_cast.position = cast_at + Vector2(70, 0)

	var t := create_tween().set_parallel(true)
	t.tween_property(_backdrop, "modulate:a", 1.0, 0.6)
	t.tween_property(_crest, "modulate:a", 1.0, 0.5).set_delay(0.25)
	t.tween_property(_crest, "position", crest_at, 0.7).set_delay(0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_cast, "modulate:a", 1.0, 0.6).set_delay(0.45)
	t.tween_property(_cast, "position", cast_at, 0.8).set_delay(0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_idle)

## The slow loops that keep the picture alive once everything has arrived.
func _idle() -> void:
	var drift := create_tween().set_loops()
	drift.tween_property(_backdrop, "scale", Vector2(1.05, 1.05), 18.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.tween_property(_backdrop, "scale", Vector2.ONE, 18.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var y := _crest.position.y
	var bob := create_tween().set_loops()
	bob.tween_property(_crest, "position:y", y - 6.0, 2.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(_crest, "position:y", y, 2.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var breathe := create_tween().set_loops()
	breathe.tween_property(_cast, "scale", Vector2(1.0, 1.012), 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(_cast, "scale", Vector2.ONE, 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Once the game can start, the button says so.
func _beckon() -> void:
	if _calm:
		return
	var pulse := create_tween().set_loops()
	pulse.tween_property(_start, "scale", Vector2(1.05, 1.05), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(_start, "scale", Vector2.ONE, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# — start-up —————————————————————————————————————————————

func _warm_up() -> void:
	# Catalogue first: the home and chapter-map screens both need it.
	if ContentManager.catalog.is_empty():
		ContentManager.load_local_catalog()
	if ContentManager.catalog.is_empty():
		_fail("فهرست محتوا خوانده نشد.", "catalog_missing")
		return
	if SaveManager.has_save():
		if not SaveManager.load_game():
			Log.error("Boot", "save present but unreadable")
			_fail("پروندهٔ ذخیره خوانده نشد.", "save_unreadable")
			return
	_ready_to_play = true
	_start.disabled = false
	_status.text = ""
	_beckon()

func _fail(message: String, reason: String) -> void:
	_status.text = message
	await get_tree().create_timer(1.2).timeout
	Router.go("UI-16", {"reason": reason})

func _play() -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	if SaveManager.has_save() and not GameState.current_chapter.is_empty():
		Router.go("UI-04")
	else:
		Router.go("UI-02")

# — the crest ——————————————————————————————————————————————

class _Crest extends Control:
	## The painted crest with the game's name written on its plaque.
	##
	## The name is set in type rather than painted, so it is real Persian in
	## the game's own face — an image model cannot be trusted with Persian
	## letters — and it can be changed without repainting anything.
	var texture: Texture2D
	var title: String = ""

	func _draw() -> void:
		if texture == null:
			return
		var ts := texture.get_size()
		var k := minf(size.x / ts.x, size.y / ts.y)
		var drawn := ts * k
		var at := (size - drawn) * 0.5
		draw_texture_rect(texture, Rect2(at, drawn), false)

		var font: Font = Style.font_bold if Style.font_bold != null else Style.font_regular
		if font == null or title.is_empty():
			return
		var field := Rect2(at + drawn * PLAQUE.position, drawn * PLAQUE.size)
		var px := int(field.size.y * 0.80)
		var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		if w > field.size.x * 0.92:
			px = int(px * field.size.x * 0.92 / w)
			w = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		# draw_string takes a baseline: centre the glyphs' ascent-to-descent
		# box in the field, not their top edge.
		var base := field.position.y + (field.size.y
			+ font.get_ascent(px) - font.get_descent(px)) * 0.5
		var pos := Vector2(field.position.x + (field.size.x - w) * 0.5, base)
		draw_string_outline(font, pos + Vector2(0, 3), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, px, 10, Color(0.02, 0.03, 0.08, 0.9))
		draw_string_outline(font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
			6, Color("5A3609"))
		draw_string(font, pos + Vector2(0, 2), title, HORIZONTAL_ALIGNMENT_LEFT,
			-1, px, Palette.GOLD_DEEP)
		draw_string(font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
			Palette.GOLD_LIGHT)
