extends Node
## Builds Razino's theme once at startup and applies it to the whole tree.
##
## Doing this in code rather than a .tres keeps every colour, radius and font
## size traceable to Palette, so the sixteen screens cannot drift apart. It
## also lets the theme react to the player's text-size setting without
## shipping several theme files.
##
## The gilding lives in OrnateBox, handed to the theme here — which is why no
## screen contains any drawing code of its own.

signal theme_rebuilt()

const FONT_REGULAR := "res://assets/fonts/Vazirmatn-Regular.ttf"
const FONT_MEDIUM := "res://assets/fonts/Vazirmatn-Medium.ttf"
const FONT_BOLD := "res://assets/fonts/Vazirmatn-Bold.ttf"

var theme: Theme
var font_regular: Font
var font_medium: Font
var font_bold: Font

func _ready() -> void:
	_load_fonts()
	rebuild()
	Settings.changed.connect(func(key: String):
		if key == "text_scale":
			rebuild()
	)

func _load_fonts() -> void:
	font_regular = _load_font(FONT_REGULAR)
	font_medium = _load_font(FONT_MEDIUM)
	font_bold = _load_font(FONT_BOLD)
	if font_regular == null:
		Log.error("Style", "Persian font missing — text will fall back to the engine default and will not shape correctly")

func _load_font(path: String) -> Font:
	if not ResourceLoader.exists(path):
		return null
	var res := ResourceLoader.load(path)
	return res as Font

func scaled(size: int) -> int:
	return int(round(size * Settings.text_scale))

func rebuild() -> void:
	theme = Theme.new()
	if font_regular != null:
		theme.default_font = font_regular
	theme.default_font_size = scaled(Palette.FS_BODY)

	_style_buttons()
	_style_panels()
	_style_labels()
	_style_inputs()
	_style_misc()

	var root := get_tree().root
	if root != null:
		root.theme = theme
	theme_rebuilt.emit()
	Log.info("Style", "theme built (text scale %.2f)" % Settings.text_scale)

# — the box factory ———————————————————————————————————————

func _box(kind: OrnateBox.Kind, top: Color, bottom: Color, radius: float = Palette.R_LG,
		frame: float = Palette.FRAME_W, h: int = Palette.PAD_MD, v: int = Palette.PAD_SM) -> OrnateBox:
	return OrnateBox.make(kind, top, bottom, radius, frame).with_margins(h, v)

func _flat(bg: Color, radius: float, border: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(radius))
	sb.content_margin_left = Palette.PAD_MD
	sb.content_margin_right = Palette.PAD_MD
	sb.content_margin_top = Palette.PAD_SM
	sb.content_margin_bottom = Palette.PAD_SM
	if border_w > 0:
		sb.set_border_width_all(border_w)
		sb.border_color = border
	return sb

## The four faces of a button, in one place so every variant bevels alike.
## A press flips the gradient, which is what makes it feel physical.
func button_faces(top: Color, bottom: Color, radius: float = Palette.R_MD) -> Dictionary:
	return {
		"normal": _box(OrnateBox.Kind.BUTTON, top, bottom, radius, 2.5),
		"hover": _box(OrnateBox.Kind.BUTTON, top.lightened(0.12), bottom.lightened(0.12), radius, 2.5),
		"pressed": _box(OrnateBox.Kind.BUTTON, bottom, top, radius, 2.5),
		"disabled": _box(OrnateBox.Kind.BUTTON, Palette.LOCKED.lightened(0.08),
			Palette.LOCKED.darkened(0.35), radius, 2.0),
	}

func _style_buttons() -> void:
	# Primary action — gold, the metal the whole frame is made of.
	var gold := button_faces(Palette.GOLD_BRIGHT, Palette.GOLD_DEEP)
	for state in gold:
		theme.set_stylebox(state, "Button", gold[state])
	theme.set_stylebox("focus", "Button", _box(OrnateBox.Kind.WELL,
		Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.04), Palette.R_MD, 2.0))
	theme.set_color("font_color", "Button", Palette.INK)
	theme.set_color("font_hover_color", "Button", Palette.INK)
	theme.set_color("font_pressed_color", "Button", Palette.INK)
	theme.set_color("font_focus_color", "Button", Palette.INK)
	theme.set_color("font_disabled_color", "Button", Palette.PANEL_DEEP)
	theme.set_font_size("font_size", "Button", scaled(Palette.FS_LABEL))
	if font_bold != null:
		theme.set_font("font", "Button", font_bold)

	theme.set_stylebox("normal", "CheckButton", _box(OrnateBox.Kind.WELL,
		Palette.PANEL_DEEP, Palette.PANEL, Palette.R_MD))
	theme.set_stylebox("hover", "CheckButton", _box(OrnateBox.Kind.WELL,
		Palette.PANEL, Palette.PANEL_LIGHT, Palette.R_MD))
	theme.set_stylebox("pressed", "CheckButton", _box(OrnateBox.Kind.WELL,
		Palette.PANEL_DEEP, Palette.PANEL, Palette.R_MD))
	theme.set_color("font_color", "CheckButton", Palette.SNOW)
	theme.set_color("font_hover_color", "CheckButton", Palette.SNOW)
	theme.set_color("font_pressed_color", "CheckButton", Palette.GOLD_BRIGHT)
	var on := WidgetArt.switch(true)
	var off := WidgetArt.switch(false)
	# In an RTL layout Godot reaches for the mirrored icons, so both sets have
	# to be supplied or the engine's own grey switch shows through.
	for key in ["checked", "checked_disabled", "checked_mirrored", "checked_disabled_mirrored"]:
		theme.set_icon(key, "CheckButton", on)
	for key in ["unchecked", "unchecked_disabled", "unchecked_mirrored", "unchecked_disabled_mirrored"]:
		theme.set_icon(key, "CheckButton", off)
	theme.set_font_size("font_size", "CheckButton", scaled(Palette.FS_LABEL))

func _style_panels() -> void:
	var panel := _box(OrnateBox.Kind.PANEL, Palette.PANEL_LIGHT, Palette.PANEL_DEEP,
		Palette.R_LG, Palette.FRAME_W, Palette.PAD_MD, Palette.PAD_MD)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PopupPanel", panel)

func _style_labels() -> void:
	theme.set_color("font_color", "Label", Palette.SNOW)
	theme.set_font_size("font_size", "Label", scaled(Palette.FS_BODY))
	theme.set_color("default_color", "RichTextLabel", Palette.SNOW)
	theme.set_font_size("normal_font_size", "RichTextLabel", scaled(Palette.FS_BODY))
	if font_regular != null:
		theme.set_font("normal_font", "RichTextLabel", font_regular)
	if font_bold != null:
		theme.set_font("bold_font", "RichTextLabel", font_bold)

func _style_inputs() -> void:
	# A field has to read as a field on parchment as well as on night blue, so
	# it is near-white with a standing gold border rather than the panel colour.
	theme.set_stylebox("normal", "LineEdit", _box(OrnateBox.Kind.PARCHMENT,
		Color("FDFBF7"), Palette.PARCHMENT_DIM, Palette.R_SM, 2.0))
	theme.set_stylebox("focus", "LineEdit", _box(OrnateBox.Kind.PARCHMENT,
		Color("FFFFFF"), Palette.PARCHMENT, Palette.R_SM, 3.0))
	theme.set_color("font_color", "LineEdit", Palette.INK)
	theme.set_color("font_placeholder_color", "LineEdit", Palette.INK_SOFT)
	theme.set_color("caret_color", "LineEdit", Palette.INK)
	theme.set_font_size("font_size", "LineEdit", scaled(Palette.FS_BODY))

	# A slider needs a visible track: the well alone was dark on dark, so the
	# filled part is gold and the empty part a lit groove.
	theme.set_stylebox("slider", "HSlider", _box(OrnateBox.Kind.WELL,
		Palette.NIGHT, Palette.PANEL, 9.0, 2.0, 0, 7))
	theme.set_stylebox("grabber_area", "HSlider", _box(OrnateBox.Kind.BARE,
		Palette.GOLD_BRIGHT, Palette.GOLD_DEEP, 9.0, 0.0, 0, 7))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box(OrnateBox.Kind.BARE,
		Palette.GOLD_BRIGHT, Palette.GOLD, 9.0, 0.0, 0, 7))
	var knob := WidgetArt.knob(34)
	theme.set_icon("grabber", "HSlider", knob)
	theme.set_icon("grabber_highlight", "HSlider", knob)
	theme.set_icon("grabber_disabled", "HSlider", WidgetArt.knob(28))

func _style_misc() -> void:
	theme.set_stylebox("background", "ProgressBar", _box(OrnateBox.Kind.BARE,
		Palette.NIGHT, Palette.PANEL_DEEP, Palette.R_SM, 0.0, 0, 0))
	theme.set_stylebox("fill", "ProgressBar", _box(OrnateBox.Kind.BARE,
		Palette.TEAL_LIGHT, Palette.TEAL_DEEP, Palette.R_SM, 0.0, 0, 0))
	theme.set_color("font_color", "ProgressBar", Palette.SNOW)
	theme.set_constant("separation", "VBoxContainer", Palette.PAD_SM)
	theme.set_constant("separation", "HBoxContainer", Palette.PAD_SM)
	theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

## Assigns the theme directly to a control.
##
## Godot propagates a theme down through Control and Window nodes, but a plain
## Node in the chain breaks that walk — so a screen parented under one would
## silently fall back to the engine's default grey. Every root UI node calls
## this instead of trusting its ancestry.
func attach(control: Control) -> void:
	if control != null and theme != null:
		control.theme = theme


# — small helpers shared by the screens ———————————————————

## Pale text has to survive falling on painted art; dark ink on parchment must
## not be embossed. So the shadow follows the colour, not the theme.
func _shade_for_background(l: Label, colour: Color) -> void:
	if colour.get_luminance() < 0.5:
		return
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_outline_size", 2)


## A heading that reads as a heading on every screen.
func make_title(text: String, size: int = Palette.FS_TITLE, color: Color = Palette.GOLD_BRIGHT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", scaled(size))
	l.add_theme_color_override("font_color", color)
	if font_bold != null:
		l.add_theme_font_override("font", font_bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shade_for_background(l, color)
	return l

func make_body(text: String, size: int = Palette.FS_BODY, color: Color = Palette.SNOW_SOFT,
		wrap: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", scaled(size))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# A wrapping label inside a row can shrink to a single glyph per line, so
	# anything laid out horizontally asks for wrap = false.
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	_shade_for_background(l, color)
	return l

## Buttons are at least Palette.TOUCH_MIN tall, per GDD §7.2.
func make_button(text: String, variant: String = "primary", icon: String = "") -> Button:
	var b := Button.new()
	b.text = text
	# Wide enough to read and to hit; height is the GDD's touch minimum.
	b.custom_minimum_size = Vector2(130, Palette.TOUCH_MIN)
	b.focus_mode = Control.FOCUS_ALL
	var faces := {}
	match variant:
		"secondary":
			faces = button_faces(Palette.TEAL_LIGHT, Palette.TEAL_DEEP)
		"quiet":
			faces = button_faces(Palette.PANEL_LIGHT, Palette.PANEL_DEEP)
		"danger":
			faces = button_faces(Palette.RUBY_LIGHT, Palette.RUBY.darkened(0.35))
		_:
			faces = {}
	for state in faces:
		b.add_theme_stylebox_override(state, faces[state])
	if not faces.is_empty():
		# Gold carries ink; the darker faces carry snow.
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(key, Palette.SNOW)
	if not icon.is_empty():
		var badge := IconRect.new(icon, 30.0, Palette.GOLD_BRIGHT)
		badge.medallion = true
		badge.anchor_left = 0.0
		badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		badge.offset_left = 12
		badge.offset_top = -15
		badge.offset_right = 42
		badge.offset_bottom = 15
		b.add_child(badge)
		b.custom_minimum_size.x += 44
	return b

## A parchment card — used for anything the player reads closely.
func make_card(radius: float = Palette.R_LG) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PARCHMENT,
		Color("FBF1DA"), Palette.PARCHMENT_DIM, radius, 3.0, Palette.PAD_MD, Palette.PAD_MD))
	return p

func make_night_card(radius: float = Palette.R_LG) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PANEL,
		Palette.PANEL_LIGHT, Palette.PANEL_DEEP, radius, Palette.FRAME_W,
		Palette.PAD_MD, Palette.PAD_MD))
	return p

## An inset row — list items, inventory slots, anything in a column.
func make_well(radius: float = Palette.R_MD) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.WELL,
		Palette.PANEL_DEEP, Palette.PANEL, radius, 2.0, Palette.PAD_MD, Palette.PAD_SM))
	return p

## A gold plaque for a title or a section heading.
func make_plaque(text: String, size: int = Palette.FS_HEADING) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PLAQUE,
		Palette.PANEL_LIGHT, Palette.PANEL_DEEP, Palette.R_MD, Palette.FRAME_W,
		Palette.PAD_LG, Palette.PAD_SM))
	var l := make_title(text, size, Palette.GOLD_BRIGHT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

## A currency chip: medallion plus count, as seen top-right on every screen.
func make_chip(icon: String, amount: int, colour: Color = Palette.GOLD_BRIGHT) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.WELL,
		Palette.PANEL_DEEP, Palette.NIGHT, Palette.R_LG, 2.0, Palette.PAD_MD, Palette.PAD_XS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_XS)
	row.add_child(IconRect.new(icon, 32.0, colour))
	var count := make_body(Fa.num(amount), Palette.FS_LABEL, Palette.SNOW, false)
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(count)
	p.add_child(row)
	return p

## A small framed tile carrying a motif — the stand-in for art that is not
## painted yet, and the frame real art will sit in once it is.
func make_art_tile(icon: String, side: Vector2, lit: bool = true) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = side
	var top := Palette.PANEL_LIGHT if lit else Palette.PANEL_DEEP
	var bottom := Palette.PANEL_DEEP if lit else Palette.NIGHT
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PARCHMENT,
		top, bottom, Palette.R_MD, 2.5, Palette.PAD_XS, Palette.PAD_XS))
	var badge := IconRect.new(icon, minf(side.x, side.y) * 0.6,
		Palette.GOLD_BRIGHT if lit else Palette.LOCKED)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(badge)
	return p

## A framed tile showing a painting, falling back to the motif tile when that
## art has not been painted yet.
func make_art_frame(art_id: String, icon: String, side: Vector2,
		lit: bool = true, chapter_id: String = "") -> Control:
	var painted := SceneArt.load_texture(art_id, chapter_id)
	if painted == null:
		return make_art_tile(icon, side, lit)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = side
	frame.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PARCHMENT,
		Palette.PANEL_LIGHT, Palette.PANEL_DEEP, Palette.R_MD, 2.5, 3, 3))
	frame.clip_contents = true
	var art := TextureRect.new()
	art.texture = painted
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A locked place is shown drained rather than hidden, so the player can
	# see there is somewhere to go.
	if not lit:
		art.modulate = Color(0.45, 0.5, 0.58, 1.0)
	frame.add_child(art)
	return frame

## A wide banner at the head of a screen.
func make_banner(art_id: String, height: float) -> Control:
	var painted := SceneArt.load_texture(art_id)
	if painted == null:
		var stand_in := PlaceholderArt.new()
		stand_in.background_id = art_id
		stand_in.custom_minimum_size = Vector2(0, height)
		stand_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return stand_in
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, height)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PARCHMENT,
		Palette.PANEL_LIGHT, Palette.PANEL_DEEP, Palette.R_MD, 3.0, 4, 4))
	var art := TextureRect.new()
	art.texture = painted
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	return frame
