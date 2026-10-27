extends Control
## UI-01 — the start screen, laid out as the approved sheet draws it.
##
## It is the painted vista, the cast standing on the path, the title plate,
## a column of three medallions down the left and one button. Almost all of
## it is art rather than layout, which is why this screen can match the
## sheet exactly where a data-driven screen cannot.
##
## It is also the one place that decides where a returning player lands:
## straight back into their chapter if they have progress, the intro if they
## do not. The warm-up runs while the player is still looking at the
## picture, so the button is live by the time they reach for it.

const SIDE_ACTIONS := [
	{"icon": "gear", "label": "تنظیمات", "ui": "UI-13"},
	{"icon": "friend", "label": "پروفایل", "ui": "UI-17"},
	{"icon": "book", "label": "راهنما", "ui": "UI-02"},
]

var _start: Button
var _status: Label
var _ready_to_play: bool = false

func _ready() -> void:
	Log.info("Boot", "starting")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	Style.attach(self)
	_build()
	await get_tree().process_frame
	await _warm_up()

func _build() -> void:
	# — the painting —
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	var vista := UiArt.plate("splash_vista")
	if vista != null:
		var art := TextureRect.new()
		art.texture = vista
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)

	# — the cast, standing on the path —
	var cast := UiArt.plate("splash_cast")
	if cast != null:
		var group := TextureRect.new()
		group.texture = cast
		group.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		group.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Anchored to the bottom centre so the group keeps its footing on
		# any aspect ratio instead of floating.
		group.anchor_left = 0.18
		group.anchor_right = 0.84
		group.anchor_top = 0.30
		group.anchor_bottom = 0.84
		add_child(group)

	# — the title —
	var logo := LogoPlate.new()
	logo.anchor_left = 0.30
	logo.anchor_right = 0.70
	logo.anchor_top = 0.03
	logo.anchor_bottom = 0.33
	add_child(logo)

	# — the three medallions down the left —
	var column := VBoxContainer.new()
	column.layout_direction = Control.LAYOUT_DIRECTION_LTR
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", Palette.PAD_SM)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	column.offset_left = 26
	# Wide enough for the longest label to sit on one line. At the medallion's
	# own width "تنظیمات" wrapped to one glyph per line and read as a column
	# of unrelated letters.
	column.offset_right = 190
	column.offset_top = -150
	column.offset_bottom = 150
	add_child(column)
	for action in SIDE_ACTIONS:
		column.add_child(_side_action(action))

	# — the one button —
	var bottom := VBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", Palette.PAD_XS)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -170
	bottom.offset_bottom = -34
	add_child(bottom)

	_start = Style.make_button("شروع بازی")
	_start.custom_minimum_size = Vector2(420, 84)
	_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start.add_theme_font_size_override("font_size", Style.scaled(Palette.FS_TITLE))
	_start.disabled = true
	_start.pressed.connect(_play)
	bottom.add_child(_start)

	_status = Style.make_body("در حال آماده‌سازی…", Palette.FS_CAPTION, Palette.SNOW)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_status)

func _side_action(action: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	var medal := Medallion.new(String(action["icon"]), 64.0)
	medal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	col.add_child(label)
	return col

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
