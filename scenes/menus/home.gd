extends RazinoScreen
## UI-04 — خانه, laid out as the approved mockup draws it (docs/UI_SPEC.md §3.2).
##
## The town is the screen. Everything else floats on it: the player capsule
## top left, the purse top right, a column of menu pills down the left side,
## and at the bottom the chapter plate with the one button that matters.
##
## GDD §5 screen 1 still rules the content: within a couple of seconds a
## child should see where they are and where they can carry on. So the big
## button is always "continue", and the chapter it continues sits above it.

const MENU := [
	{"label": "نقشه جهان", "icon": "compass", "ui": "UI-05"},
	{"label": "فصل‌ها", "icon": "map", "ui": "UI-10"},
	{"label": "کوله‌پشتی", "icon": "backpack", "ui": "UI-19"},
	{"label": "سرنخ‌ها", "icon": "magnifier", "ui": "UI-08"},
	{"label": "فروشگاه", "icon": "box", "ui": "UI-11"},
]

## The row the mockup keeps off the child's main path.
const SECONDARY := [
	{"label": "پروفایل", "icon": "friend", "ui": "UI-17"},
	{"label": "اعلان‌ها", "icon": "bell", "ui": "UI-18"},
	{"label": "لباس‌ها", "icon": "star", "ui": "UI-12"},
	{"label": "دانلودها", "icon": "download", "ui": "UI-15"},
	{"label": "بخش والدین", "icon": "shield", "ui": "UI-14"},
]

func _ready() -> void:
	# No plaque: the town carries the screen, as in the mockup.
	configure("", "", "town", true)
	super._ready()

func build_content() -> void:
	# The player capsule takes the place of the title, top left.
	var badge := Style.make_player_badge(
		GameState.player_name, GameState.level, GameState.xp, GameState.xp_for_next_level())
	header.add_child(badge)
	header.move_child(badge, 0)

	var body := HBoxContainer.new()
	# Menu on the left, town showing through on the right, as the mockup
	# draws it.
	body.layout_direction = Control.LAYOUT_DIRECTION_LTR
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.PAD_LG)
	content.add_child(body)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", Palette.PAD_SM)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(menu)
	for entry in MENU:
		menu.add_child(_menu_pill(entry))

	# The town shows through here; nothing is drawn over the middle.
	var open := Control.new()
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(open)

	# — the chapter plate and the one button that matters —
	var bottom := VBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.add_theme_constant_override("separation", Palette.PAD_XS)
	content.add_child(bottom)

	var chapter_id := _resume_chapter()
	var entry := ContentManager.catalog_entry(chapter_id)
	var plate := Style.make_two_line_plaque(
		_chapter_ordinal(chapter_id), String(entry.get("title", "راز ساعت خاموش")))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.custom_minimum_size.x = 420
	bottom.add_child(plate)

	var percent := GameState.chapter_percent(chapter_id, int(entry.get("scene_count", 1)))
	var meter := Style.make_meter(percent, 420.0)
	meter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom.add_child(meter)
	var big := Style.make_button(_continue_label(), "gold")
	big.custom_minimum_size = Vector2(340, 66)
	big.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	big.add_theme_font_size_override("font_size", Style.scaled(Palette.FS_HEADING))
	big.pressed.connect(_continue)
	bottom.add_child(big)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	bottom.add_child(row)
	bottom.move_child(row, 0)
	for entry2 in SECONDARY:
		var m := Medallion.new(String(entry2["icon"]), 44.0)
		m.tooltip_text = String(entry2["label"])
		var ui_id := String(entry2["ui"])
		m.pressed.connect(func():
			AudioManager.play_sfx("SFX_UI_TAP")
			Router.go(ui_id))
		row.add_child(m)

func _menu_pill(entry: Dictionary) -> Button:
	var b := Style.make_menu_button(String(entry["label"]), String(entry["icon"]))
	var ui_id := String(entry["ui"])
	b.pressed.connect(func():
		AudioManager.play_sfx("SFX_UI_TAP")
		Router.go(ui_id))
	return b

func _resume_chapter() -> String:
	var chapter_id := GameState.current_chapter
	return chapter_id if not chapter_id.is_empty() else "season_01"

## "فصل اول" and so on, for the small line of the chapter plate.
func _chapter_ordinal(chapter_id: String) -> String:
	var n := int(chapter_id.replace("season_", ""))
	var words := ["", "اول", "دوم", "سوم", "چهارم", "پنجم",
		"ششم", "هفتم", "هشتم", "نهم", "دهم"]
	return "فصل %s" % (words[n] if n > 0 and n < words.size() else Fa.num(n))

func _continue_label() -> String:
	return "ادامهٔ بازی" if not GameState.current_scene.is_empty() else "شروع بازی"

func _continue() -> void:
	Router.go("UI-06", {"chapter_id": _resume_chapter(), "resume": true})
