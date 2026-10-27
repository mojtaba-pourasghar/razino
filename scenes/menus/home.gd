extends Control
## UI-04 — صفحهٔ اصلی, built to docs/DESIGN.md.
##
## Laid out the way the approved sheet lays out its main menu: the painting
## fills the window, the title sits over it, and one column of buttons runs
## down the start side with exactly one of them gold. Four earlier versions
## of this screen were designed from taste and rejected; the numbers in
## RazinoUI come from the sheet now, and this screen only arranges them.
##
## GDD §5 screen 1 still rules the content: within a couple of seconds a
## child must see where they are and where to carry on. So the gold button —
## the one thing on the screen filled with the action colour — is always the
## one that resumes their chapter.

const MENU := [
	{"label": "ادامهٔ بازی", "icon": "play", "ui": "UI-20", "primary": true},
	{"label": "نقشهٔ جهان", "icon": "compass", "ui": "UI-05"},
	{"label": "فصل‌ها", "icon": "map", "ui": "UI-10"},
	{"label": "کوله‌پشتی", "icon": "backpack", "ui": "UI-19"},
	{"label": "سرنخ‌ها", "icon": "magnifier", "ui": "UI-08"},
	{"label": "تنظیمات", "icon": "gear", "ui": "UI-13"},
]

## Kept off the child's main path, as the sheet keeps them: small round
## buttons in the corner rather than another column.
const SECONDARY := [
	{"icon": "friend", "ui": "UI-17", "tip": "پروفایل"},
	{"icon": "bell", "ui": "UI-18", "tip": "اعلان‌ها"},
	{"icon": "box", "ui": "UI-11", "tip": "فروشگاه"},
	{"icon": "shield", "ui": "UI-14", "tip": "بخش والدین"},
]

const SAFE := 24

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	Style.attach(self)
	_build_backdrop()
	_build_purse()
	_build_menu()
	_build_secondary()
	_build_footer()

# — the painting ———————————————————————————————————————————

func _build_backdrop() -> void:
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	var art_path := ""
	for path in ["res://assets/art/backgrounds/ui_town.webp",
			"res://assets/art/backgrounds/ui_splash.webp"]:
		if ResourceLoader.exists(path):
			art_path = path
			break
	if not art_path.is_empty():
		var art := TextureRect.new()
		art.texture = load(art_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)

	# A gradient scrim down the start side only. The sheet keeps the far side
	# of the painting bright and darkens the side the menu sits on, which is
	# what lets white Persian sit on the menu and the town still read as day.
	var scrim := _Scrim.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

# — the purse, top end ————————————————————————————————————

func _build_purse() -> void:
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.offset_right = -SAFE
	row.offset_top = SAFE
	row.add_theme_constant_override("separation", RazinoUI.TOUCH_GAP)
	add_child(row)
	row.add_child(_chip("coin", GameState.coins, Palette.GOLD_BRIGHT))
	row.add_child(_chip("gem", GameState.gems, Palette.BLUE))

func _chip(icon: String, amount: int, colour: Color) -> Control:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel",
		UiBox.make(UiBox.Kind.PANEL_PLAIN, 14, 7).with_radius(999.0))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", 6)
	chip.add_child(row)
	var badge := IconRect.new(icon, 28.0, colour)
	badge.painted = false
	row.add_child(badge)
	var n := Style.make_body(Fa.num(amount), Palette.FS_LABEL, Palette.SNOW, false)
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(n)
	return chip

# — the menu column ————————————————————————————————————————

func _build_menu() -> void:
	var holder := VBoxContainer.new()
	# Anchored by hand, so RTL must not mirror it: the sheet puts the menu on
	# the start side and the painting's subject on the other, and that is the
	# composition. The Persian inside each row still reads right to left.
	holder.layout_direction = Control.LAYOUT_DIRECTION_LTR
	holder.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	holder.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	holder.offset_right = -SAFE
	holder.offset_left = -SAFE - 360
	holder.offset_top = -230
	holder.offset_bottom = 230
	holder.add_theme_constant_override("separation", 10)
	add_child(holder)

	var title := Style.make_title("رازینو", Palette.FS_TITLE + 16, Palette.GOLD_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	holder.add_child(title)

	var tagline := Style.make_body("ماجرا آغاز می‌شود", Palette.FS_CAPTION,
		Palette.SNOW_SOFT, false)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(tagline)

	var gap := Control.new()
	gap.custom_minimum_size.y = 10
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(gap)

	for entry: Dictionary in MENU:
		holder.add_child(_menu_button(entry))

## One menu row: icon at the start, label beside it, on a dark surface — or
## on the one gold surface, if this is the thing the child came back for.
func _menu_button(entry: Dictionary) -> Button:
	var primary := bool(entry.get("primary", false))
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 64.0 if primary else 56.0)
	b.focus_mode = Control.FOCUS_ALL
	var kind := UiBox.Kind.PRIMARY if primary else UiBox.Kind.BUTTON
	var base := UiBox.make(kind, 16, 10)
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("hover", base.state(false, true))
	b.add_theme_stylebox_override("focus", base.state(false, true))
	b.add_theme_stylebox_override("pressed", base.state(true, false))
	b.add_theme_stylebox_override("disabled", base)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_right = -18
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	var label := Style.make_body(String(entry["label"]), Palette.FS_HEADING,
		Palette.SNOW, false)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	# The sheet draws these icons flat white, with no ring around them.
	var icon := IconRect.new(String(entry["icon"]), 34.0, Palette.SNOW)
	icon.painted = false
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	# Mirrors the label's column so the icon sits at the far edge and the
	# text stays centred between the two.
	var balance := Control.new()
	balance.custom_minimum_size.x = 34
	balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(balance)

	var ui_id := String(entry["ui"])
	var payload: Dictionary = {"chapter_id": _chapter_id()} if primary else {}
	b.pressed.connect(func(): _go(ui_id, payload))
	return b

# — corners ————————————————————————————————————————————————

func _build_secondary() -> void:
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	# Along the bottom middle, clear of both the menu column on the start
	# side and the player card on the other.
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_left = 300
	row.offset_right = -400
	row.offset_bottom = -SAFE
	row.add_theme_constant_override("separation", RazinoUI.TOUCH_GAP)
	add_child(row)
	for entry: Dictionary in SECONDARY:
		row.add_child(_round_button(String(entry["icon"]), String(entry["tip"]),
			String(entry["ui"])))

func _round_button(icon: String, tip: String, ui_id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(RazinoUI.TOUCH_MIN, RazinoUI.TOUCH_MIN)
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var art := _Round.new()
	art.icon = icon
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	b.pressed.connect(func(): _go(ui_id))
	return b

## The player, bottom start corner: portrait, name, level and the experience
## bar — the same card the sheet puts in the corner of its gameplay screen.
func _build_footer() -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiBox.make(UiBox.Kind.PANEL, 12, 10))
	card.layout_direction = Control.LAYOUT_DIRECTION_LTR
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	card.offset_left = SAFE
	card.offset_bottom = -SAFE
	add_child(card)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	card.add_child(row)

	var face := _Portrait.new()
	face.art = CastArt.face("player")
	face.custom_minimum_size = Vector2(56, 56)
	row.add_child(face)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(col)

	var line := HBoxContainer.new()
	line.layout_direction = Control.LAYOUT_DIRECTION_RTL
	line.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(line)
	var who := GameState.player_name if not GameState.player_name.is_empty() else "بازیکن"
	line.add_child(Style.make_body(who, Palette.FS_LABEL, Palette.SNOW, false))
	line.add_child(Style.make_body("سطح %s" % Fa.num(GameState.level),
		Palette.FS_CAPTION, Palette.GOLD_BRIGHT, false))

	var xp := _Bar.new()
	xp.ratio = clampf(float(GameState.xp) / maxf(1.0, float(GameState.xp_for_next_level())), 0.0, 1.0)
	xp.colour = Palette.BLUE
	xp.custom_minimum_size = Vector2(180, 12)
	col.add_child(xp)

# — content ————————————————————————————————————————————————

func _chapter_id() -> String:
	var id := GameState.current_chapter
	return id if not id.is_empty() else "season_01"

func _go(ui_id: String, payload: Dictionary = {}) -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	Router.go(ui_id, payload)

# — drawn pieces ——————————————————————————————————————————

class _Scrim extends Control:
	func _draw() -> void:
		var ci := get_canvas_item()
		# Darkest at the start edge, clear by the middle. Twenty slices is
		# past what the eye can band at this contrast.
		# Slices laid end to end from the middle to the start edge, each one
		# darker than the last. An earlier version computed each slice's x
		# from the same term twice and left gaps between them, which read as
		# vertical stripes across the painting.
		var bands := 28
		var reach := size.x * 0.54
		var w := reach / float(bands) + 1.0
		for i in bands:
			var t := float(i) / float(bands - 1)
			CI.rect(ci, Rect2(size.x - reach + reach * t, 0, w, size.y),
				Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b,
					0.86 * t * t))
		# A light wash over the whole picture, so nothing sits on raw paint.
		CI.rect(ci, Rect2(Vector2.ZERO, size),
			Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, 0.22))

class _Round extends Control:
	var icon: String = "gear"
	func _draw() -> void:
		var ci := get_canvas_item()
		var centre := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		RazinoUI.disc(ci, centre, r, Palette.PANEL_DEEP)
		GameIcons.draw(ci, icon, centre, r * 0.5, Palette.SNOW)

class _Portrait extends Control:
	var art: Texture2D = null
	func _draw() -> void:
		var ci := get_canvas_item()
		var centre := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		RazinoUI.disc(ci, centre, r, Palette.PANEL, true)
		if art != null:
			draw_texture_rect(art,
				Rect2(centre - Vector2(r, r) * 0.86, Vector2(r, r) * 1.72), false)
		CI.arc(ci, centre, r - 1.0, 0.0, TAU, Palette.GOLD_DEEP, 2.0, 48)

class _Bar extends Control:
	var ratio: float = 0.0
	var colour: Color = Palette.BLUE
	func _draw() -> void:
		RazinoUI.bar(get_canvas_item(), Rect2(Vector2.ZERO, size), ratio, colour)
