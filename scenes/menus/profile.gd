extends RazinoScreen
## UI-17 — پروفایل, as the approved sheet draws it: the player's portrait and
## stat list on one side, what they are carrying on the other.
##
## Nothing here is a gate. The level is a keepsake, not a requirement — a
## child who plays slowly must never be locked out of the story (GDD §5.3).

const TABS := ["آواتار", "آمار", "دستاوردها"]

var _tab: int = 0
var _tab_row: HBoxContainer
var _detail: VBoxContainer

func _ready() -> void:
	configure("پروفایل", "UI-04", "panel", true)
	super._ready()

func build_content() -> void:
	var body := HBoxContainer.new()
	body.layout_direction = Control.LAYOUT_DIRECTION_LTR
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.PAD_MD)
	content.add_child(body)

	body.add_child(_identity_panel())

	var right := Style.make_section()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rcol := Style.section_body(right)

	_tab_row = HBoxContainer.new()
	_tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tab_row.add_theme_constant_override("separation", Palette.PAD_SM)
	rcol.add_child(_tab_row)

	_detail = VBoxContainer.new()
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", Palette.PAD_SM)
	rcol.add_child(_detail)

	_build_tabs()
	_build_detail()

	var go := Style.make_button("ادامه", "primary", "play")
	go.custom_minimum_size = Vector2(280, 66)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func(): Router.go("UI-04"))
	content.add_child(go)

## Portrait, name and the stat list beneath it.
func _identity_panel() -> Control:
	var panel := Style.make_section()
	panel.custom_minimum_size.x = 330
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Style.section_body(panel).add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", Palette.PAD_SM)
	scroll.add_child(col)

	var portrait := AvatarPortrait.new()
	portrait.custom_minimum_size = Vector2(240, 230)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(portrait)

	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", Palette.PAD_SM)
	var shown := GameState.player_name if not GameState.player_name.is_empty() else "ماجراجو"
	var plate := Style.make_corner_plaque(shown, Palette.FS_HEADING)
	name_row.add_child(plate)
	var edit := Medallion.new("pencil", 44.0)
	edit.tooltip_text = "تغییر نام و ظاهر"
	edit.pressed.connect(func(): Router.go("UI-12"))
	name_row.add_child(edit)
	col.add_child(name_row)

	col.add_child(Style.make_stat_row("trophy", "سطح", Fa.num(GameState.level)))
	var xp_bar := Style.make_meter(
		float(GameState.xp) / maxf(float(GameState.xp_for_next_level()), 1.0), 220.0)
	col.add_child(Style.make_control_row("star", "تجربه", xp_bar))
	col.add_child(Style.make_stat_row("magnifier", "سرنخ‌ها",
		Fa.num(GameState.clues.size())))
	col.add_child(Style.make_stat_row("box", "وسیله‌ها",
		Fa.num(GameState.inventory.size())))
	col.add_child(Style.make_stat_row("book", "فصل‌های تمام‌شده",
		Fa.num(_chapters_complete())))
	return panel

func _build_tabs() -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	var buttons := Style.make_tabs(TABS, _tab)
	for i in buttons.size():
		var index := i
		buttons[i].pressed.connect(func():
			_tab = index
			_build_tabs()
			_build_detail())
		_tab_row.add_child(buttons[i])

func _build_detail() -> void:
	for child in _detail.get_children():
		child.queue_free()
	match _tab:
		0: _build_items()
		1: _build_stats()
		_: _build_achievements()

func _build_items() -> void:
	_detail.add_child(Style.make_body("موجودی آیتم‌ها", Palette.FS_LABEL, Palette.GOLD_LIGHT))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", Palette.PAD_SM)
	grid.add_theme_constant_override("v_separation", Palette.PAD_SM)
	_detail.add_child(grid)
	var icons := _item_icons()
	for i in 10:
		grid.add_child(Style.make_item_slot(icons[i] if i < icons.size() else ""))
	_detail.add_child(Style.make_quote(
		"هر چیزی که برمی‌داری یک روز به کار می‌آید. عجله نکن."))

func _build_stats() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	row.add_child(Style.make_stat_tile("map", "مأموریت‌ها", _chapters_started()))
	row.add_child(Style.make_stat_tile("trophy", "جایزه‌ها", _chapters_complete()))
	row.add_child(Style.make_stat_tile("magnifier", "سرنخ‌ها", GameState.clues.size()))
	for child in row.get_children():
		(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_child(row)
	_detail.add_child(Style.make_stat_row("coin", "سکه", Fa.num(GameState.coins), Palette.ORANGE))
	_detail.add_child(Style.make_stat_row("gem", "الماس", Fa.num(GameState.gems), Palette.BLUE))

func _build_achievements() -> void:
	# Honest: the achievement set is not designed yet, so this says so
	# rather than showing invented rows.
	_detail.add_child(Style.make_quote(
		"دستاوردها هنوز طراحی نشده‌اند. وقتی اضافه شوند، همین‌جا نشان داده می‌شوند."))

func _chapters_complete() -> int:
	var n := 0
	for cid in GameState.chapter_progress.keys():
		if GameState.is_chapter_complete(String(cid)):
			n += 1
	return n

func _chapters_started() -> int:
	return GameState.chapter_progress.size()

## The icons for whatever the player is actually carrying.
func _item_icons() -> Array:
	var map := {
		"ITEM_MAP_PIECE": "map", "ITEM_NOTEBOOK": "book", "ITEM_BRASS_KEY": "key",
		"ITEM_GEAR_TEN": "gear", "ITEM_TOOLS": "gear", "ITEM_LEVER": "gear",
		"ITEM_UNDERMAP": "map", "ITEM_RECORDER": "speaker", "ITEM_TENTH_KEY": "key",
	}
	var out: Array = []
	for item_id in GameState.inventory.keys():
		out.append(String(map.get(String(item_id), "star")))
	return out
