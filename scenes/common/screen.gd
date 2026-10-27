class_name RazinoScreen
extends Control
## Base for every screen in GDD §7.1.
##
## Gives each screen the same bones from docs/UI_SPEC.md: a painted backdrop
## seen through a gilded frame, a safe-area margin that keeps content off
## notches and rounded corners, and a top bar of a back medallion, a CORNER
## title plaque and the player's purse. Screens override `build_content()`
## and nothing else.
##
## The plaque is deliberately small and set into the corner. An earlier pass
## gave every screen a full-width gold banner; the approved mockup does not,
## and the banner was eating the top sixth of every screen.

var header: HBoxContainer
var content: VBoxContainer
var background: Control
## The gilded border, kept apart from `background` so a gameplay screen can
## hide the backdrop and still be framed.
var screen_edge: Control

var _title_text: String = ""
var _back_target: String = ""
var _backdrop: String = "panel"
## The glyph on the title plaque, as every panel of the sheet carries one.
var _title_icon: String = "book"
var _show_purse: bool = false

## Keeps the layout usable on a narrow phone without shrinking text below
## readability (GDD §7.2, last bullet).
const SAFE_MARGIN := 28
const MAX_CONTENT_WIDTH := 1100

## The painted backdrops. Each is a scene, not a UI element — the gilding on
## top is drawn, so the two never fight for the same pixels.
const BACKDROPS := {
	"panel": "res://assets/art/backgrounds/ui_panel_backdrop.webp",
	"town": "res://assets/art/backgrounds/ui_town.webp",
	"worldmap": "res://assets/art/backgrounds/ui_worldmap.webp",
	"splash": "res://assets/art/backgrounds/ui_splash.webp",
}

var _margin: MarginContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	Style.attach(self)
	_build_shell()
	build_content()
	resized.connect(_apply_side_margins)
	_apply_side_margins()

## Content fills a phone or tablet, and is reined in on a very wide window so
## lines never run to an unreadable length.
func _apply_side_margins() -> void:
	if _margin == null:
		return
	var side := maxi(SAFE_MARGIN, int((size.x - MAX_CONTENT_WIDTH) * 0.5))
	_margin.add_theme_constant_override("margin_left", side)
	_margin.add_theme_constant_override("margin_right", side)

## Overridden by each screen.
func build_content() -> void:
	pass

## Called by subclasses before build_content() runs, from configure().
func configure(title: String, back_to: String = "", backdrop: String = "panel",
		show_purse: bool = false, icon: String = "book") -> void:
	_title_text = title
	_title_icon = icon
	_back_target = back_to
	_backdrop = backdrop
	_show_purse = show_purse

func _build_shell() -> void:
	_build_backdrop()

	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, SAFE_MARGIN)
	add_child(_margin)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", Palette.PAD_MD)
	_margin.add_child(column)

	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", Palette.PAD_SM)
	# The mockup fixes the top bar: back and player on the left, purse and
	# gear on the right. That order is part of the design, not a consequence
	# of reading direction, so this row is not mirrored.
	header.layout_direction = Control.LAYOUT_DIRECTION_LTR
	column.add_child(header)
	_build_header()

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", Palette.PAD_MD)
	column.add_child(content)

## The painted art, then a dark wash so white Persian text stays legible over
## it, then a gilded border around the whole window.
func _build_backdrop() -> void:
	background = Control.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var fill := ColorRect.new()
	fill.color = Palette.NIGHT
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(fill)

	var path: String = BACKDROPS.get(_backdrop, BACKDROPS["panel"])
	if ResourceLoader.exists(path):
		var art := TextureRect.new()
		art.texture = load(path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.add_child(art)
	else:
		Log.warn("Screen", "backdrop missing: %s" % path)

	# Nearly opaque. In the sheet a panel screen sits on near-black with the
	# painting only just readable behind it; at 0.58 the art competed with
	# every hairline on top of it.
	var wash := ColorRect.new()
	wash.color = Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, 0.88)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(wash)

	# No border around the window. In the approved sheets a screen is panels
	# on a painting; the window itself has no frame, and the one that used
	# to be here was the last thing left over from the ornate pass.

## The top bar every panel of the sheet carries.
##
## Title at the START edge inside a dark plaque with its own icon; the purse
## and the gear at the END edge. The sheet never centres a title — an
## earlier version did, and every screen read as a dialog box rather than a
## page of a game.
func _build_header() -> void:
	if not _title_text.is_empty():
		header.add_child(_title_plaque())

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(gap)

	if _show_purse:
		header.add_child(_chip("coin", GameState.coins, Palette.GOLD_BRIGHT))
		header.add_child(_chip("gem", GameState.gems, Palette.BLUE))

	var gear := _disc_button("gear", "تنظیمات", "UI-13")
	header.add_child(gear)

	if not _back_target.is_empty():
		header.add_child(_disc_button("play", "بازگشت", _back_target))

## A dark plaque carrying an icon and the screen's name.
func _title_plaque() -> Control:
	var plaque := PanelContainer.new()
	plaque.add_theme_stylebox_override("panel",
		UiBox.make(UiBox.Kind.PANEL, 16, 9))
	plaque.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	plaque.add_child(row)
	var badge := IconRect.new(_title_icon, 30.0, Palette.GOLD_BRIGHT)
	badge.painted = false
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(badge)
	var l := Style.make_title(_title_text, Palette.FS_HEADING, Palette.SNOW)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(l)
	return plaque

func _chip(icon: String, amount: int, colour: Color) -> Control:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel",
		UiBox.make(UiBox.Kind.PANEL_PLAIN, 14, 8).with_radius(999.0))
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

func _disc_button(icon: String, tip: String, ui_id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(RazinoUI.TOUCH_MIN, RazinoUI.TOUCH_MIN)
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var art := _Disc.new()
	art.icon = icon
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	b.pressed.connect(func(): Router.go(ui_id))
	return b

class _Disc extends Control:
	var icon: String = "gear"
	func _draw() -> void:
		var ci := get_canvas_item()
		var centre := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		RazinoUI.disc(ci, centre, r, Palette.PANEL_DEEP)
		GameIcons.draw(ci, icon, centre, r * 0.48, Palette.SNOW)

## A scrollable area for screens with more content than fits.
func make_scroll() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", Palette.PAD_MD)
	scroll.add_child(inner)
	return inner

## One row of label + control, laid out right to left.
func make_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	var l := Style.make_body(label_text, Palette.FS_LABEL, Palette.SNOW)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row

## A short message bar used for errors and confirmations.
func make_notice(text: String, tone: Color = Palette.RUBY) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", OrnateBox.make(
		OrnateBox.Kind.WELL, tone.darkened(0.5), tone.darkened(0.7), Palette.R_MD, 2.0
	).with_margins(Palette.PAD_MD, Palette.PAD_SM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	row.add_child(IconRect.new("shield", 28.0, tone.lightened(0.4)))
	var l := Style.make_body(text, Palette.FS_LABEL, Palette.SNOW)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	panel.add_child(row)
	return panel
