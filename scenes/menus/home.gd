extends Control
## UI-04 — صفحهٔ اصلی, matched to the approved sheet's main-menu panel.
##
## Every position here is a fraction read off `assets/art/reference/
## screens.webp`, not a layout I arranged. The panel is specific and the
## brief was "exactly this": the painting runs edge to edge at full
## brightness, the emblem and title sit above the middle, one narrow column
## of buttons runs down the centre with the first one gold, and the version
## sits in the bottom corner. Nothing else is on the screen — no purse, no
## player card, no round corner buttons. Earlier versions of this screen had
## all three and none of them are in the sheet.

## Where each piece sits, as a fraction of the window. Measured against the
## sheet; see docs/DESIGN.md.
const SPOT := {
	"emblem": Rect2(0.505, 0.055, 0.095, 0.170),
	"title": Rect2(0.390, 0.200, 0.325, 0.150),
	"tagline": Rect2(0.390, 0.390, 0.325, 0.055),
	"menu": Rect2(0.407, 0.480, 0.260, 0.470),
	"version": Rect2(0.025, 0.930, 0.120, 0.050),
}

const MENU := [
	{"label": "شروع بازی", "icon": "play", "ui": "UI-20", "primary": true},
	{"label": "ادامهٔ بازی", "icon": "book", "ui": "UI-20"},
	{"label": "تنظیمات", "icon": "gear", "ui": "UI-13"},
	{"label": "راهنما", "icon": "map", "ui": "UI-02"},
	{"label": "خروج", "icon": "home", "ui": "UI-01"},
]

var _placed: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	Style.attach(self)
	_build()
	resized.connect(_place_all)
	_place_all()

func _build() -> void:
	# — the painting, full brightness —
	#
	# No scrim over it. The sheet's menu sits on bright daylight and stays
	# readable because every button has its own dark surface; a wash across
	# the picture was the first thing that made this screen look unlike the
	# sheet.
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	for path in ["res://assets/art/backgrounds/ui_splash.webp",
			"res://assets/art/backgrounds/ui_town.webp"]:
		if not ResourceLoader.exists(path):
			continue
		var art := TextureRect.new()
		art.texture = load(path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
		break

	# — the emblem and the name —
	var emblem := _Emblem.new()
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(emblem, "emblem")

	var title := _Title.new()
	title.text = "رازینو"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(title, "title")

	var tagline := Style.make_title("ماجرا آغاز می‌شود", Palette.FS_LABEL, Palette.SNOW)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place(tagline, "tagline")

	# — the column —
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_place(column, "menu")
	for entry: Dictionary in MENU:
		column.add_child(_menu_button(entry))

	var version := Style.make_body("v%s" % ProjectSettings.get_setting(
		"application/config/version", "0.1.0"), Palette.FS_CAPTION,
		Palette.SNOW_SOFT, false)
	version.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_place(version, "version")

## One menu row: the icon pinned to the start edge, the label centred in the
## rest of the button — which is the sheet's arrangement and not something
## Godot's own button text can do, so the label is a child.
func _menu_button(entry: Dictionary) -> Button:
	var primary := bool(entry.get("primary", false))
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, RazinoUI.TOUCH_MIN + (8 if primary else 0))
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	var base := UiBox.make(UiBox.Kind.PRIMARY if primary else UiBox.Kind.BUTTON, 14, 8)
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("hover", base.state(false, true))
	b.add_theme_stylebox_override("focus", base.state(false, true))
	b.add_theme_stylebox_override("pressed", base.state(true, false))
	b.add_theme_stylebox_override("disabled", base)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -16
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	var icon := IconRect.new(String(entry["icon"]), 30.0, Palette.SNOW)
	icon.painted = false
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var label := Style.make_body(String(entry["label"]), Palette.FS_HEADING,
		Palette.SNOW, false)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	# Balances the icon's column so the label is centred in the button, not
	# in what is left of it.
	var pad := Control.new()
	pad.custom_minimum_size.x = 30
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pad)

	var ui_id := String(entry["ui"])
	var payload: Dictionary = {"chapter_id": _chapter_id()} \
		if ui_id == "UI-20" else {}
	b.pressed.connect(func(): _go(ui_id, payload))
	return b

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

# — content ————————————————————————————————————————————————

func _chapter_id() -> String:
	var id := GameState.current_chapter
	return id if not id.is_empty() else "season_01"

func _go(ui_id: String, payload: Dictionary = {}) -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	Router.go(ui_id, payload)

# — drawn pieces ——————————————————————————————————————————

class _Emblem extends Control:
	## The gold shield with a compass rose, above the name.
	func _draw() -> void:
		var ci := get_canvas_item()
		var centre := size * 0.5
		var r := minf(size.x, size.y) * 0.46

		# The shield: a gold disc with eight points around it.
		for i in 8:
			var a := TAU * float(i) / 8.0
			var tip := centre + Vector2(cos(a), sin(a)) * r * 1.30
			var l := centre + Vector2(cos(a + 0.28), sin(a + 0.28)) * r * 0.86
			var rr := centre + Vector2(cos(a - 0.28), sin(a - 0.28)) * r * 0.86
			CI.poly(ci, PackedVector2Array([tip, l, rr]), Palette.GOLD_DEEP)
		CI.circle(ci, centre, r, Palette.GOLD_DEEP)
		CI.circle(ci, centre, r * 0.92, Palette.GOLD_BRIGHT)
		CI.circle(ci, centre, r * 0.76, Color("0C2A4E"))

		# The compass rose inside it.
		for i in 4:
			var a := PI * 0.5 * float(i) - PI * 0.5
			var tip := centre + Vector2(cos(a), sin(a)) * r * 0.70
			var w := Vector2(-sin(a), cos(a)) * r * 0.16
			CI.poly(ci, PackedVector2Array([tip, centre + w, centre - w]),
				Palette.SNOW if i % 2 == 0 else Palette.GOLD_BRIGHT)
		CI.circle(ci, centre, r * 0.12, Palette.GOLD_BRIGHT)

class _Title extends Control:
	## The game's name in gold, with the dark outline the sheet gives it.
	##
	## Drawn rather than set as a Label because the sheet's title carries a
	## heavy dark edge and a lit top, and a theme font override cannot do
	## either — it would be flat gold on a bright sky and disappear.
	var text: String = ""
	func _draw() -> void:
		var font := Style.font_bold if Style.font_bold != null else Style.font_regular
		if font == null:
			return
		var px := int(minf(size.y * 0.78, size.x * 0.34))
		var measured := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER,
			-1.0, px)
		# draw_string takes a baseline, not a top edge, so the ascent has to
		# be added back or the name floats above its own box.
		var at := Vector2((size.x - measured.x) * 0.5,
			size.y * 0.5 + font.get_ascent(px) * 0.5)
		for offset: Vector2 in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3),
				Vector2(0, 3), Vector2(-3, -3), Vector2(3, 3)]:
			draw_string(font, at + offset, text, HORIZONTAL_ALIGNMENT_LEFT,
				-1.0, px, Color("2A1A06"))
		draw_string(font, at + Vector2(0, 2), text, HORIZONTAL_ALIGNMENT_LEFT,
			-1.0, px, Palette.GOLD_DEEP)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px,
			Palette.GOLD_BRIGHT)
