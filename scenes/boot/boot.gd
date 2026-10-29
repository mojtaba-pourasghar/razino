extends Control
## UI-01 — the start screen, built as the approved sheet's main-menu panel
## (assets/art/reference/screens.webp, top left).
##
## A bright painted valley with the castle on the right, the hero and
## Fandogh on their rock on the left looking towards it, the compass crest
## over the gold name in the middle, and one column of buttons under it with
## the first one gold. Every piece is its own painting on transparent ground
## (content_tools/paint_splash.py), so each one comes in on its own and
## keeps a little life once it has: the valley drifts behind everything and
## specks of sunlight rise. Nothing in front of the picture moves. All of
## it stops when the player has asked for reduced motion.
##
## It is also the one place that decides where a returning player lands:
## straight back into their chapter if they have progress, the intro if they
## do not. The warm-up runs while the player is still looking at the
## picture, so the buttons are live by the time they reach for them.

const ART := "res://assets/art/splash/"

## Where each piece sits, as a fraction of the window, read off the sheet.
## The screen itself is laid out left to right — these are places in the
## picture, not reading order — and every text inside it is RTL on its own.
const SPOT := {
	"hero": Rect2(0.00, 0.16, 0.35, 0.86),
	"crest": Rect2(0.44, 0.015, 0.12, 0.20),
	"title": Rect2(0.36, 0.14, 0.28, 0.24),
	"tagline": Rect2(0.36, 0.375, 0.28, 0.06),
	"menu": Rect2(0.385, 0.455, 0.23, 0.455),
	"status": Rect2(0.36, 0.92, 0.28, 0.05),
	"version": Rect2(0.012, 0.93, 0.10, 0.05),
}

## The column, top to bottom. `needs_save` greys a button out until there
## is a game to come back to.
const MENU := [
	{"id": "start", "label": "شروع بازی", "icon": "play", "primary": true},
	{"id": "continue", "label": "ادامهٔ بازی", "icon": "map", "needs_save": true},
	{"id": "settings", "label": "تنظیمات", "icon": "gear"},
	{"id": "guide", "label": "راهنما", "icon": "book"},
	{"id": "quit", "label": "خروج", "icon": "home"},
]

## Text and icon on the gold button: dark enough to read on amber, warm
## enough not to look printed.
const INK := Color("3A1E06")

var _status: Label
var _ready_to_play: bool = false
var _calm: bool = false

var _backdrop: TextureRect
var _hero: TextureRect
var _crest: TextureRect
var _title: TextureRect
var _buttons: Array[Button] = []
var _needs_save: Array[Button] = []
var _placed: Array[Dictionary] = []

func _ready() -> void:
	Log.info("Boot", "starting")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	_calm = Settings.reduce_motion
	Style.attach(self)
	_build()
	resized.connect(_place_all)
	_place_all()
	await get_tree().process_frame
	_pivots()
	_enter()
	await _warm_up()

func _build() -> void:
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	# — the valley —
	_backdrop = _picture("menu_bg_night.webp", TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	# A soft shade behind the middle column, darkest under the buttons, so
	# the title and the labels hold against bright sky and forest. The sheet
	# has no visible panel there and neither does this: only the light dips.
	add_child(_shade())

	if not _calm:
		add_child(_motes())

	# — the hero on his rock —
	_hero = _picture("menu_hero.png", TextureRect.STRETCH_KEEP_ASPECT)
	_place(_hero, "hero")

	# — the crest and the name —
	_title = _picture("menu_title.png", TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_place(_title, "title")
	_crest = _picture("menu_crest.png", TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_place(_crest, "crest")

	var tagline := Style.make_title("ماجرا آغاز می‌شود", Palette.FS_LABEL, Palette.SNOW)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	tagline.add_theme_color_override("font_outline_color", Color(0.03, 0.06, 0.14, 0.95))
	tagline.add_theme_constant_override("outline_size", 9)
	_place(tagline, "tagline")

	# — the column —
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_place(column, "menu")
	for entry: Dictionary in MENU:
		var b := _menu_button(entry)
		column.add_child(b)
		_buttons.append(b)
		if bool(entry.get("needs_save", false)):
			_needs_save.append(b)

	_status = Style.make_body("در حال آماده‌سازی…", Palette.FS_CAPTION, Palette.SNOW, false)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_status.add_theme_constant_override("outline_size", 6)
	_place(_status, "status")

	var version := Style.make_body("v%s" % ProjectSettings.get_setting(
		"application/config/version", "0.1.0"), Palette.FS_CAPTION,
		Palette.SNOW, false)
	version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	version.add_theme_constant_override("outline_size", 5)
	_place(version, "version")

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

## Night, faded radially out from the middle of the button column.
func _shade() -> TextureRect:
	var g := Gradient.new()
	var dark := Palette.NIGHT
	dark.a = 0.42
	var clear := Palette.NIGHT
	clear.a = 0.0
	g.set_color(0, dark)
	g.set_color(1, clear)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.62)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 128
	tex.height = 128
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.anchor_left = 0.25
	rect.anchor_right = 0.75
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## One row of the column: the painted plate, the icon at the left edge and
## the label centred in the button, as the sheet draws it.
func _menu_button(entry: Dictionary) -> Button:
	var primary := bool(entry.get("primary", false))
	var ink := INK if primary else Palette.SNOW
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, RazinoUI.TOUCH_MIN)
	b.disabled = true

	# The kit's plates (assets/art/kit), the same buttons every other screen
	# wears; UiBox paints them and lights them on hover and press.
	var base := UiBox.make(UiBox.Kind.PRIMARY if primary else UiBox.Kind.BUTTON, 14, 8)
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("hover", base.state(false, true))
	b.add_theme_stylebox_override("focus", base.state(false, true))
	b.add_theme_stylebox_override("pressed", base.state(true, false))
	b.add_theme_stylebox_override("disabled", base.state(true, false))

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_right = -18
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	var icon := IconRect.new(String(entry["icon"]), 26.0, ink)
	icon.painted = false
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var label := Style.make_body(String(entry["label"]), Palette.FS_HEADING, ink, false)
	if Style.font_bold != null:
		label.add_theme_font_override("font", Style.font_bold)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	row.add_child(label)

	# Balances the icon's column so the label is centred in the button, not
	# in what is left of it.
	var pad := Control.new()
	pad.custom_minimum_size.x = 26
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pad)

	var id := String(entry["id"])
	b.pressed.connect(func(): _choose(id))
	return b

## Specks of sunlight drifting up through the valley.
func _motes() -> CPUParticles2D:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.97, 0.8, 1.0))
	g.set_color(1, Color(1.0, 0.9, 0.5, 0.0))
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
	fade.add_point(0.2, Color(1, 1, 1, 0.8))
	fade.add_point(0.8, Color(1, 1, 1, 0.5))

	var p := CPUParticles2D.new()
	p.name = "Motes"
	p.texture = dot
	p.amount = 30
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2(0.2, -1)
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 26.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.9
	p.color_ramp = fade
	return p

# — placing by fraction ———————————————————————————————————

func _place(control: Control, spot: String) -> void:
	add_child(control)
	_placed.append({"node": control, "spot": SPOT[spot]})

## Everything is positioned as a fraction of the window rather than in
## pixels, so the composition holds its proportions from a 19:9 phone to a
## 4:3 tablet instead of drifting apart on each.
func _place_all() -> void:
	for entry: Dictionary in _placed:
		var control: Control = entry["node"]
		var f: Rect2 = entry["spot"]
		control.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		control.anchor_left = f.position.x
		control.anchor_top = f.position.y
		control.anchor_right = f.position.x + f.size.x
		control.anchor_bottom = f.position.y + f.size.y
		control.offset_left = 0.0
		control.offset_top = 0.0
		control.offset_right = 0.0
		control.offset_bottom = 0.0
	_pivots()
	var motes := get_node_or_null("Motes") as CPUParticles2D
	if motes != null:
		motes.position = Vector2(size.x * 0.5, size.y * 0.95)
		motes.emission_rect_extents = Vector2(size.x * 0.5, size.y * 0.05)

func _pivots() -> void:
	if _backdrop == null:
		return
	_backdrop.pivot_offset = _backdrop.size * 0.5
	_hero.pivot_offset = Vector2(_hero.size.x * 0.5, _hero.size.y)
	_crest.pivot_offset = _crest.size * 0.5
	_title.pivot_offset = _title.size * 0.5
	for b in _buttons:
		b.pivot_offset = b.size * 0.5

# — motion ————————————————————————————————————————————————

func _enter() -> void:
	if _calm:
		return
	var hero_at := _hero.position
	var crest_at := _crest.position
	_backdrop.modulate.a = 0.0
	_hero.modulate.a = 0.0
	_hero.position = hero_at - Vector2(80, 0)
	_crest.modulate.a = 0.0
	_crest.position = crest_at - Vector2(0, 50)
	_title.modulate.a = 0.0
	_title.scale = Vector2(0.75, 0.75)

	var t := create_tween().set_parallel(true)
	t.tween_property(_backdrop, "modulate:a", 1.0, 0.6)
	t.tween_property(_hero, "modulate:a", 1.0, 0.6).set_delay(0.2)
	t.tween_property(_hero, "position", hero_at, 0.8).set_delay(0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_title, "modulate:a", 1.0, 0.35).set_delay(0.35)
	t.tween_property(_title, "scale", Vector2.ONE, 0.6).set_delay(0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_crest, "modulate:a", 1.0, 0.4).set_delay(0.55)
	t.tween_property(_crest, "position", crest_at, 0.7).set_delay(0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in _buttons.size():
		var b := _buttons[i]
		b.modulate.a = 0.0
		b.scale = Vector2(0.9, 0.9)
		var at := 0.7 + 0.08 * i
		t.tween_property(b, "modulate:a", 1.0, 0.3).set_delay(at)
		t.tween_property(b, "scale", Vector2.ONE, 0.4).set_delay(at) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_idle)

## The one slow loop that keeps the picture alive once everything arrives.
##
## There used to be three more: the crest bobbed five pixels every 2.2s, the
## hero "breathed" at 1.01 scale — seven pixels of head travel every 1.9s
## from a bottom pivot — and the start button pulsed at 1.04 every 0.9s,
## the fastest beat on the fullest part of the screen. Four loops at four
## tempos, none in step, read as the whole menu shaking rather than as life.
##
## What is left moves the painting behind everything by about two pixels a
## second, which the eye reads as depth and never as motion. Anything the
## player is trying to look at or press now holds perfectly still.
func _idle() -> void:
	var drift := create_tween().set_loops()
	drift.tween_property(_backdrop, "scale", Vector2(1.02, 1.02), 24.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.tween_property(_backdrop, "scale", Vector2.ONE, 24.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Once the game can start, the gold button says so.
func _beckon() -> void:
	if _calm or _buttons.is_empty():
		return
	# A glow, not a change of size. Scaling the gold button moved its edges
	# six pixels every beat, which made the one thing the player is meant to
	# press the least steady thing on the screen.
	var start := _buttons[0]
	var pulse := create_tween().set_loops()
	pulse.tween_property(start, "modulate", Color(1.14, 1.12, 1.06), 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(start, "modulate", Color.WHITE, 1.4) \
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
	var resumable := _has_progress()
	for b in _buttons:
		b.disabled = b in _needs_save and not resumable
	_status.text = ""
	_beckon()

func _has_progress() -> bool:
	return SaveManager.has_save() and not GameState.current_chapter.is_empty()

func _fail(message: String, reason: String) -> void:
	_status.text = message
	await get_tree().create_timer(1.2).timeout
	Router.go("UI-16", {"reason": reason})

func _choose(id: String) -> void:
	if not _ready_to_play:
		return
	AudioManager.play_sfx("SFX_UI_TAP")
	match id:
		"start":
			Router.go("UI-04" if _has_progress() else "UI-02")
		"continue":
			Router.go("UI-04")
		"settings":
			Router.go("UI-13")
		"guide":
			Router.go("UI-02")
		"quit":
			get_tree().quit()
