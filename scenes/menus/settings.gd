extends RazinoScreen
## UI-13 — تنظیمات, laid out as the approved sheet's settings panel.
##
## A navigation column down the start side with the section you are in lit
## gold, and beside it the rows for that section: a label over its control,
## one under the other, with a hairline separating the two halves.
##
## The content is still what GDD §12.2 requires: three independent volumes
## and the accessibility switches a child who is still learning needs.

const SECTIONS := [
	{"label": "گرافیک", "icon": "star"},
	{"label": "صدا", "icon": "speaker"},
	{"label": "بازی", "icon": "gear"},
	{"label": "زبان", "icon": "globe"},
]

var _section: int = 0
var _nav: VBoxContainer
var _rows: VBoxContainer

func _ready() -> void:
	configure("تنظیمات", "UI-04", "panel", false, "gear")
	super._ready()

func build_content() -> void:
	var body := HBoxContainer.new()
	body.layout_direction = Control.LAYOUT_DIRECTION_RTL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.PAD_MD)
	content.add_child(body)

	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", Style._box(
		OrnateBox.Kind.PANEL, Palette.PANEL_DEEP, Palette.NIGHT,
		RazinoUI.RADIUS, 0.0, 12, 14))
	left.custom_minimum_size.x = 250
	body.add_child(left)
	_nav = VBoxContainer.new()
	_nav.add_theme_constant_override("separation", 8)
	left.add_child(_nav)

	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", Style._box(
		OrnateBox.Kind.PANEL, Palette.PANEL_DEEP, Palette.NIGHT,
		RazinoUI.RADIUS, 0.0, 22, 18))
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	_rows = VBoxContainer.new()
	_rows.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_rows.add_theme_constant_override("separation", Palette.PAD_MD)
	right.add_child(_rows)

	_build_nav()
	_build_rows()

func _build_nav() -> void:
	for child in _nav.get_children():
		child.queue_free()
	for i in SECTIONS.size():
		var entry: Dictionary = SECTIONS[i]
		var item := Style.make_nav_item(String(entry["icon"]),
			String(entry["label"]), i == _section)
		var index := i
		item.pressed.connect(func():
			_section = index
			AudioManager.play_sfx("SFX_UI_TAP")
			_build_nav()
			_build_rows())
		_nav.add_child(item)

func _build_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	match _section:
		0: _graphics()
		1: _sound()
		2: _play()
		_: _language()

func _graphics() -> void:
	_rows.add_child(_choice("کیفیت گرافیک", ["بالا", "متوسط", "پایین"], 0))
	_rows.add_child(_toggle("افکت‌های ویژه", not Settings.reduce_motion,
		func(on): Settings.set_value("reduce_motion", not on)))
	_rows.add_child(_toggle("حالت تمام‌صفحه",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
		func(on): DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if on
			else DisplayServer.WINDOW_MODE_WINDOWED)))

func _sound() -> void:
	for row: Array in [["صدای موسیقی", "music_volume"],
			["صدای افکت‌ها", "sfx_volume"], ["صدای گویندگان", "voice_volume"]]:
		_rows.add_child(_slider(String(row[0]), String(row[1])))

func _play() -> void:
	_rows.add_child(_toggle("رفتن خودکار به خط بعد", Settings.auto_advance,
		func(on): Settings.set_value("auto_advance", on)))
	_rows.add_child(_toggle("نمایش زیرنویس", Settings.subtitles_enabled,
		func(on): Settings.set_value("subtitles_enabled", on)))

func _language() -> void:
	_rows.add_child(_choice("زبان بازی", ["فارسی"], 0))
	_rows.add_child(Style.make_quote(
		"بازی فعلاً فقط فارسی است. زبان‌های دیگر با فصل‌های تازه می‌آیند."))

## A label with its control under it, the way the sheet stacks them.
func _stacked(label: String, control: Control) -> Control:
	var col := VBoxContainer.new()
	col.layout_direction = Control.LAYOUT_DIRECTION_RTL
	col.add_theme_constant_override("separation", 6)
	col.add_child(Style.make_body(label, Palette.FS_LABEL, Palette.SNOW, false))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(control)
	return col

## A row where the control sits beside its label, for switches — which is
## how the sheet draws those and nothing else.
func _beside(label: String, control: Control) -> Control:
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	var l := Style.make_body(label, Palette.FS_LABEL, Palette.SNOW, false)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)
	return row

func _toggle(label: String, on: bool, when: Callable) -> Control:
	var t := Style.make_toggle(on)
	t.toggled.connect(func(v): when.call(v))
	return _beside(label, t)

func _slider(label: String, key: String) -> Control:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = Settings.get(key)
	s.custom_minimum_size.y = 28
	s.value_changed.connect(func(v): Settings.set_value(key, v))
	return _stacked(label, s)

## The sheet's dropdown: a wide dark field with a chevron at its end.
func _choice(label: String, options: Array, chosen: int) -> Control:
	var b := OptionButton.new()
	for o in options:
		b.add_item(String(o))
	b.selected = chosen
	b.custom_minimum_size.y = RazinoUI.TOUCH_MIN
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var box := UiBox.painted(UiBox.Kind.BUTTON, 16, 10)
	if box != null:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(state, box)
	return _stacked(label, b)
