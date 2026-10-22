extends RazinoScreen
## UI-13 — تنظیمات, laid out as the approved sheet draws it: a navigation
## column on the left, the chosen group's rows on the right, and one save
## button along the bottom.
##
## The content is still what GDD §12.2 requires — three independent volumes —
## plus the accessibility switches that make the game readable for a child
## who is still learning: subtitle size, keeping subtitles on, reduced motion
## and auto-advance.

const GROUPS := [
	{"id": "audio", "icon": "speaker", "label": "صدا"},
	{"id": "reading", "icon": "book", "label": "خواندن و دیدن"},
	{"id": "account", "icon": "friend", "label": "حساب کاربری"},
	{"id": "about", "icon": "shield", "label": "اطلاعات بازی"},
]

var _group: String = "audio"
var _nav: VBoxContainer
var _rows: VBoxContainer

func _ready() -> void:
	configure("تنظیمات", "UI-04")
	super._ready()

func build_content() -> void:
	var body := HBoxContainer.new()
	body.layout_direction = Control.LAYOUT_DIRECTION_LTR
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.PAD_MD)
	content.add_child(body)

	var nav_panel := Style.make_section()
	nav_panel.custom_minimum_size.x = 230
	body.add_child(nav_panel)
	_nav = Style.section_body(nav_panel)

	var rows_panel := Style.make_section()
	rows_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rows_panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Style.section_body(rows_panel).add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", Palette.PAD_SM)
	scroll.add_child(_rows)

	_build_nav()
	_build_rows()

	var save := Style.make_button("ذخیره", "primary", "check")
	save.custom_minimum_size = Vector2(260, 66)
	save.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Settings already save as they change; this is the confirmation the
	# sheet shows, and it closes the screen.
	save.pressed.connect(func():
		AudioManager.play_sfx("SFX_UI_TAP")
		Router.go("UI-04"))
	content.add_child(save)

func _build_nav() -> void:
	for child in _nav.get_children():
		child.queue_free()
	for group in GROUPS:
		var gid := String(group["id"])
		var item := Style.make_nav_item(String(group["icon"]), String(group["label"]),
			gid == _group)
		item.pressed.connect(func():
			_group = gid
			_build_nav()
			_build_rows())
		_nav.add_child(item)

func _build_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	match _group:
		"audio":
			_rows.add_child(_slider("موسیقی", "music_volume", Settings.music_volume, 0.0, 1.0, "music"))
			_rows.add_child(_slider("افکت‌ها", "sfx_volume", Settings.sfx_volume, 0.0, 1.0, "speaker"))
			_rows.add_child(_slider("صدای گوینده", "voice_volume", Settings.voice_volume, 0.0, 1.0, "chat"))
		"reading":
			_rows.add_child(_toggle("نمایش زیرنویس", "subtitles_enabled",
				Settings.subtitles_enabled, "chat"))
			_rows.add_child(_slider("اندازهٔ متن", "text_scale", Settings.text_scale,
				0.85, 1.4, "book"))
			_rows.add_child(_toggle("کم‌کردن حرکت تصویر", "reduce_motion",
				Settings.reduce_motion, "star"))
			_rows.add_child(_toggle("ادامهٔ خودکار", "auto_advance",
				Settings.auto_advance, "play"))
			var sample := Style.make_quote("نمونهٔ متن: راز ساعت خاموش — ۱۲۳۴")
			_rows.add_child(sample)
			Style.theme_rebuilt.connect(func():
				if is_instance_valid(sample):
					queue_redraw())
		"account":
			_rows.add_child(Style.make_stat_row("friend", "نام بازیکن",
				GameState.player_name if not GameState.player_name.is_empty() else "—"))
			_rows.add_child(Style.make_stat_row("trophy", "سطح", Fa.num(GameState.level)))
			var lang := Style.make_body("فارسی", Palette.FS_LABEL, Palette.GOLD_LIGHT, false)
			_rows.add_child(Style.make_control_row("globe", "زبان", lang))
			var parent_btn := Style.make_button("بخش والدین", "quiet")
			parent_btn.pressed.connect(func(): Router.go("UI-14"))
			_rows.add_child(parent_btn)
		_:
			var version := String(ProjectSettings.get_setting("application/config/version", "?"))
			_rows.add_child(Style.make_stat_row("shield", "نسخهٔ بازی", Fa.digits(version)))
			_rows.add_child(Style.make_stat_row("book", "فونت", "وزیرمتن — SIL OFL"))
			_rows.add_child(Style.make_quote(
				"رازینو یک بازی داستانی است. هیچ معمایی با پرداخت حل نمی‌شود."))

func _slider(label: String, key: String, value: float,
		lo: float = 0.0, hi: float = 1.0, icon: String = "lamp") -> Control:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(260, Palette.TOUCH_MIN)
	s.value_changed.connect(func(v): Settings.set_value(key, v))
	return Style.make_control_row(icon, label, s)

func _toggle(label: String, key: String, value: bool, icon: String = "check") -> Control:
	var b := Style.make_toggle(value)
	b.toggled.connect(func(on): Settings.set_value(key, on))
	return Style.make_control_row(icon, label, b)
