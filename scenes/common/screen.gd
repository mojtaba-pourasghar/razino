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
		show_purse: bool = false) -> void:
	_title_text = title
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

	var wash := ColorRect.new()
	wash.color = Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, 0.58)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(wash)

	# No painted border and no drawn one. Claymorphism has no frame: a
	# surface is defined by its own thick edge and its two shadows, so a
	# second frame around the whole window is one border too many — it was
	# the last thing left over from the ornate pass.

func _build_header() -> void:
	# Left corner: the way out.
	if not _back_target.is_empty():
		var back := Medallion.new("play", Palette.MEDALLION)
		back.tooltip_text = "بازگشت"
		# RTL: the play triangle already points the way back.
		back.pressed.connect(func(): Router.go(_back_target))
		header.add_child(back)

	var left_gap := Control.new()
	left_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(left_gap)

	# Centre: the title plaque, as every sheet draws it.
	if not _title_text.is_empty():
		header.add_child(Style.make_corner_plaque(_title_text))

	var right_gap := Control.new()
	right_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(right_gap)

	# Right corner: what the player owns, then the gear.
	if _show_purse:
		header.add_child(Style.make_chip("coin", GameState.coins, Palette.ORANGE))
		header.add_child(Style.make_chip("gem", GameState.gems, Palette.BLUE))
	var gear := Medallion.new("gear", Palette.MEDALLION)
	gear.tooltip_text = "تنظیمات"
	gear.pressed.connect(func(): Router.go("UI-13"))
	header.add_child(gear)

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
