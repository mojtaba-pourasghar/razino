class_name RazinoScreen
extends Control
## Base for every screen in GDD §7.1.
##
## Gives each screen the same bones: a painted backdrop seen through a gilded
## frame, a safe-area margin that keeps content off notches and rounded
## corners, a title plaque with an optional back medallion and the player's
## purse, and a content column built right to left. Screens override
## `build_content()` and nothing else.

var header: HBoxContainer
var content: VBoxContainer
var background: Control
## The gilded border, kept apart from `background` so a gameplay screen can
## hide the backdrop and still be framed.
var screen_edge: ScreenEdge

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

	screen_edge = ScreenEdge.new()
	screen_edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_edge)

func _build_header() -> void:
	if not _back_target.is_empty():
		var back := Button.new()
		back.custom_minimum_size = Vector2(Palette.TOUCH_MIN, Palette.TOUCH_MIN)
		back.tooltip_text = "بازگشت"
		back.focus_mode = Control.FOCUS_ALL
		var faces := Style.button_faces(Palette.PANEL_LIGHT, Palette.PANEL_DEEP, Palette.TOUCH_MIN * 0.5)
		for state in faces:
			back.add_theme_stylebox_override(state, faces[state])
		var glyph := IconRect.new("play", 30.0, Palette.GOLD_BRIGHT)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# RTL: the play triangle already points the way back.
		back.add_child(glyph)
		back.pressed.connect(func(): Router.go(_back_target))
		header.add_child(back)

	if _title_text.is_empty():
		# Home and the story screens carry no plaque; the purse still needs
		# pushing to the far side, so a spacer takes the plaque's place.
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(spacer)
	else:
		var plaque := Style.make_plaque(_title_text, Palette.FS_TITLE)
		plaque.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(plaque)

	if _show_purse:
		var purse := HBoxContainer.new()
		purse.add_theme_constant_override("separation", Palette.PAD_SM)
		purse.alignment = BoxContainer.ALIGNMENT_CENTER
		purse.add_child(Style.make_chip("coin", GameState.coins, Palette.GOLD_BRIGHT))
		purse.add_child(Style.make_chip("gem", GameState.gems, Palette.TEAL_LIGHT))
		header.add_child(purse)

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
