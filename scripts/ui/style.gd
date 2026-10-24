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

## Which painted plate stands in for each drawn kind. A kind with no entry
## keeps its drawn version.
## Only the big framed panels use a painted plate.
##
## A nine-patch corner draws at its source size, so a painted ornament
## inside a 58-pixel button or a 60-pixel list card has nowhere to go and
## crumples — the notification list came out as unreadable gold scrollwork.
## Buttons, chips, plaques, cards and rows keep the drawn bevel, which holds
## its shape at any size; the sheets give those a thin gold edge anyway.
const PLATE_FOR := {
	OrnateBox.Kind.PANEL: "panel",
}

func _box(kind: OrnateBox.Kind, top: Color, bottom: Color, radius: float = Palette.R_LG,
		frame: float = Palette.FRAME_W, h: int = Palette.PAD_MD, v: int = Palette.PAD_SM) -> StyleBox:
	# A painted plate beats a drawn one wherever it exists; the drawn box
	# stays as the fallback, because the art lands a few pieces at a time.
	if PLATE_FOR.has(kind):
		var painted := UiArt.box(String(PLATE_FOR[kind]), Color.WHITE, h, v)
		if painted != null:
			return painted
	return OrnateBox.make(kind, top, bottom, radius, frame).with_margins(h, v)

## A button's faces come from a painted plate when there is one, so the
## variant picks the plate rather than a pair of colours.
func _button_box(plate: String, tint: Color, radius: float, frame: float,
		top: Color, bottom: Color) -> StyleBox:
	var painted := UiArt.box(plate, tint, Palette.PAD_MD, Palette.PAD_SM)
	if painted != null:
		return painted
	return OrnateBox.make(OrnateBox.Kind.BUTTON, top, bottom, radius, frame) \
		.with_margins(Palette.PAD_MD, Palette.PAD_SM)

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
func button_faces(top: Color, bottom: Color, radius: float = Palette.R_MD,
		plate: String = "") -> Dictionary:
	if not plate.is_empty() and UiArt.plate(plate) != null:
		# A painted face is lit by its own paint, so hover and press shift
		# its brightness rather than swapping two colours.
		return {
			"normal": UiArt.box(plate, Color.WHITE),
			"hover": UiArt.box(plate, Color(1.14, 1.14, 1.14)),
			"pressed": UiArt.box(plate, Color(0.82, 0.82, 0.82)),
			"disabled": UiArt.box(plate, Color(0.55, 0.6, 0.64)),
		}
	return {
		"normal": OrnateBox.make(OrnateBox.Kind.BUTTON, top, bottom, radius, 2.5).with_margins(Palette.PAD_MD, Palette.PAD_SM),
		"hover": OrnateBox.make(OrnateBox.Kind.BUTTON, top.lightened(0.12), bottom.lightened(0.12), radius, 2.5).with_margins(Palette.PAD_MD, Palette.PAD_SM),
		"pressed": OrnateBox.make(OrnateBox.Kind.BUTTON, bottom, top, radius, 2.5).with_margins(Palette.PAD_MD, Palette.PAD_SM),
		"disabled": OrnateBox.make(OrnateBox.Kind.BUTTON, Palette.LOCKED.lightened(0.08),
			Palette.LOCKED.darkened(0.35), radius, 2.0).with_margins(Palette.PAD_MD, Palette.PAD_SM),
	}

func _style_buttons() -> void:
	# Primary action — petrol blue with a gold edge. Gold is reserved for
	# frames and plaques, per docs/UI_SPEC.md.
	var primary := button_faces(Palette.ACTION_LIGHT, Palette.ACTION_DEEP)
	for state in primary:
		theme.set_stylebox(state, "Button", primary[state])
	theme.set_stylebox("focus", "Button", _box(OrnateBox.Kind.WELL,
		Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.04), Palette.R_MD, 2.0))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(key, "Button", Palette.GOLD_LIGHT)
	theme.set_color("font_disabled_color", "Button", Palette.LOCKED)
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
	var ink := false
	match variant:
		"gold":
			# The one gold button in the sheets: "continue" on the home screen.
			faces = button_faces(Palette.GOLD, Palette.GOLD_DEEP)
			ink = true
		"secondary":
			faces = button_faces(Palette.TEAL, Palette.TEAL_DEEP)
		"quiet":
			faces = button_faces(Palette.PANEL, Palette.PANEL_DEEP)
		"danger":
			faces = button_faces(Palette.RUBY_LIGHT, Palette.RUBY.darkened(0.35))
		_:
			faces = {}
	for state in faces:
		b.add_theme_stylebox_override(state, faces[state])
	if not faces.is_empty():
		var label_colour := Palette.INK if ink else Palette.SNOW
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(key, label_colour)
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

# — the mockup's component set (docs/UI_SPEC.md §2) ————————

## A dark pill with a gold edge: the base of chips, menu buttons and the
## player capsule.
func make_pill(h_pad: int = Palette.PAD_MD, v_pad: int = Palette.PAD_XS) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.WELL,
		Palette.PANEL, Palette.PANEL_DEEP, Palette.R_PILL, 2.0, h_pad, v_pad))
	return p

## A corner title plaque. Small and set into a corner, never full width —
## the wide centred banner was the previous design and is gone.
func make_corner_plaque(text: String, size: int = Palette.FS_TITLE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PLAQUE,
		Palette.PANEL, Palette.PANEL_DEEP, Palette.R_MD, Palette.FRAME_W,
		Palette.PAD_LG, Palette.PAD_XS))
	var l := make_title(text, size, Palette.GOLD_LIGHT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p

## The currency chip from the top right of the mockup: medallion, then count.
func make_chip(icon: String, amount: int, colour: Color = Palette.ORANGE) -> PanelContainer:
	var p := make_pill(Palette.PAD_MD, 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	row.add_child(Medallion.new(icon, 38.0, false))
	(row.get_child(0) as Medallion).icon_colour = colour
	var count := make_body(Fa.num(amount), Palette.FS_LABEL, Palette.SNOW, false)
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(count)
	p.add_child(row)
	return p

## A two-line plaque: a small line over a larger one, as the home screen's
## chapter plate and every chapter card use.
func make_two_line_plaque(small: String, large: String,
		parchment: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	if parchment:
		p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PARCHMENT,
			Palette.PARCHMENT, Palette.PARCHMENT_DIM, Palette.R_MD, 2.5,
			Palette.PAD_MD, Palette.PAD_XS))
	else:
		p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PLAQUE,
			Palette.PANEL, Palette.PANEL_DEEP, Palette.R_MD, Palette.FRAME_W,
			Palette.PAD_LG, Palette.PAD_SM))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	var top := make_body(small, Palette.FS_CAPTION,
		Palette.INK_SOFT if parchment else Palette.SNOW_SOFT, false)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(top)
	var bottom := make_title(large, Palette.FS_HEADING,
		Palette.INK if parchment else Palette.GOLD_LIGHT)
	bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(bottom)
	p.add_child(col)
	return p

## A home-screen menu entry: a pill whose icon medallion overhangs its end.
func make_menu_button(text: String, icon: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(250, Palette.TOUCH_MIN)
	b.focus_mode = Control.FOCUS_ALL
	var faces := button_faces(Palette.PANEL, Palette.PANEL_DEEP, Palette.R_PILL)
	for state in faces:
		b.add_theme_stylebox_override(state, faces[state])
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, Palette.SNOW)
	# The medallion sits on the leading edge and overhangs it, which is what
	# gives the row its silhouette in the reference sheet.
	var badge := Medallion.new(icon, Palette.MEDALLION, false)
	badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	badge.offset_left = -10
	badge.offset_right = -10 + Palette.MEDALLION
	badge.offset_top = -Palette.MEDALLION * 0.5
	badge.offset_bottom = Palette.MEDALLION * 0.5
	b.add_child(badge)
	# Keep the label clear of the medallion.
	b.add_theme_constant_override("h_separation", 0)
	var pad := int(Palette.MEDALLION)
	for state in faces:
		(faces[state] as StyleBox).content_margin_left = pad
	return b

## The player capsule: avatar medallion, name, level and experience bar.
func make_player_badge(player_name: String, level: int, xp: int, xp_max: int) -> Control:
	# Built as a plain row rather than an anchored overlay: the overhanging
	# avatar looked right but sized the text column to nothing, so the name
	# and the level were clipped to a couple of glyphs.
	var pill := make_pill(Palette.PAD_SM, Palette.PAD_XS)
	pill.layout_direction = Control.LAYOUT_DIRECTION_LTR
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	pill.add_child(row)

	var badge := Medallion.new("friend", 60.0, false)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(badge)

	var col := VBoxContainer.new()
	col.layout_direction = Control.LAYOUT_DIRECTION_LTR
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 1)
	row.add_child(col)

	var shown := player_name if not player_name.is_empty() else "بازیکن"
	var name_label := make_title(shown, Palette.FS_LABEL, Palette.SNOW)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.custom_minimum_size.x = 170
	col.add_child(name_label)

	var lvl := make_body("سطح %s" % Fa.num(level), Palette.FS_CAPTION, Palette.SNOW_SOFT, false)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(lvl)

	col.add_child(make_meter(float(xp) / maxf(float(xp_max), 1.0), 170.0))
	return pill

## A thin gold-edged meter — experience, chapter progress, downloads.
func make_meter(ratio: float, width: float = 180.0,
		fill: Color = Palette.TEAL) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, 14)
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = clampf(ratio, 0.0, 1.0)
	bar.add_theme_stylebox_override("background", _box(OrnateBox.Kind.WELL,
		Palette.NIGHT, Palette.PANEL_DEEP, Palette.R_PILL, 2.0, 0, 0))
	bar.add_theme_stylebox_override("fill", _box(OrnateBox.Kind.BARE,
		fill, fill.darkened(0.3), Palette.R_PILL, 0.0, 0, 0))
	return bar

## A row of tabs, as the inventory and profile screens use. Returns the
## buttons so the caller can connect them.
func make_tabs(labels: Array, active: int = 0) -> Array:
	var out: Array[Button] = []
	for i in labels.size():
		var b := Button.new()
		b.text = String(labels[i])
		b.custom_minimum_size = Vector2(120, 48)
		b.focus_mode = Control.FOCUS_ALL
		var on := i == active
		var faces := button_faces(
			Palette.BLUE if on else Palette.PANEL,
			Palette.BLUE.darkened(0.35) if on else Palette.PANEL_DEEP,
			Palette.R_MD)
		for state in faces:
			b.add_theme_stylebox_override(state, faces[state])
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(key, Palette.SNOW if on else Palette.SNOW_SOFT)
		out.append(b)
	return out

## A stat tile: gold icon, label, number — the profile screen's bottom row.
func make_stat_tile(icon: String, label: String, value: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.WELL,
		Palette.PANEL, Palette.PANEL_DEEP, Palette.R_MD, 2.0,
		Palette.PAD_MD, Palette.PAD_SM))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	var badge := IconRect.new(icon, 34.0, Palette.GOLD_BRIGHT)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(badge)
	var l := make_body(label, Palette.FS_CAPTION, Palette.SNOW_SOFT, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	var v := make_title(Fa.num(value), Palette.FS_HEADING, Palette.SNOW)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(v)
	p.add_child(col)
	return p

# — the sheets' panel vocabulary (docs/UI_SPEC.md) ————————

## A framed section with its own small plaque, as every panel in the sheets
## has. Returns the panel; `body` on it is where content goes.
func make_section(title: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PANEL,
		Palette.PANEL_DEEP, Palette.NIGHT, Palette.R_LG, Palette.FRAME_W,
		Palette.PAD_MD, Palette.PAD_MD))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Palette.PAD_SM)
	p.add_child(col)
	if not title.is_empty():
		var plate := make_corner_plaque(title, Palette.FS_HEADING)
		plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(plate)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(body)
	p.set_meta("body", body)
	return p

## Where a section's content goes.
func section_body(section: PanelContainer) -> VBoxContainer:
	return section.get_meta("body") as VBoxContainer

## One row of a stat list: gold medallion, Persian label, value on the far
## side, over a hairline rule. The profile and the hero panels are built of
## nothing else.
func make_stat_row(icon: String, label: String, value: String,
		value_colour: Color = Palette.SNOW) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.WELL,
		Palette.PANEL, Palette.NIGHT, Palette.R_SM, 1.5,
		Palette.PAD_SM, Palette.PAD_XS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	row.add_child(IconRect.new(icon, 30.0, Palette.GOLD_BRIGHT))
	var l := make_body(label, Palette.FS_LABEL, Palette.SNOW, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	var v := make_title(value, Palette.FS_LABEL, value_colour)
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.custom_minimum_size.x = 64
	row.add_child(v)
	p.add_child(row)
	return p

## A row with a control on the end — the settings screen's shape.
func make_control_row(icon: String, label: String, control: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.WELL,
		Palette.PANEL, Palette.NIGHT, Palette.R_SM, 1.5,
		Palette.PAD_SM, Palette.PAD_XS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	row.add_child(IconRect.new(icon, 30.0, Palette.GOLD_BRIGHT))
	var l := make_body(label, Palette.FS_LABEL, Palette.SNOW, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)
	p.add_child(row)
	return p

## An entry in a left-hand navigation list. The chosen one is filled teal,
## the rest are flat — the settings sheet's left column.
func make_nav_item(icon: String, label: String, active: bool = false) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(230, Palette.TOUCH_MIN)
	b.focus_mode = Control.FOCUS_ALL
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var faces := button_faces(
		Palette.ACTION if active else Palette.PANEL,
		Palette.ACTION_DEEP if active else Palette.NIGHT, Palette.R_MD)
	for state in faces:
		b.add_theme_stylebox_override(state, faces[state])
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, Palette.GOLD_LIGHT if active else Palette.SNOW_SOFT)
	var badge := IconRect.new(icon, 30.0,
		Palette.GOLD_BRIGHT if active else Palette.SNOW_SOFT)
	badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	badge.offset_left = -46
	badge.offset_right = -16
	badge.offset_top = -15
	badge.offset_bottom = 15
	b.add_child(badge)
	for state in faces:
		(faces[state] as StyleBox).content_margin_right = 56
	return b

## A parchment list card: medallion, a title over a subtitle, a time on the
## end. The notifications, friends and mission lists are all this card.
func make_list_card(icon: String, title: String, subtitle: String,
		trailing: String = "", badge: int = 0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PARCHMENT,
		Palette.PARCHMENT, Palette.PARCHMENT_DIM, Palette.R_MD, 2.0,
		Palette.PAD_MD, Palette.PAD_SM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	var medal := Medallion.new(icon, 46.0, false)
	medal.icon_colour = Palette.GOLD_BRIGHT
	row.add_child(medal)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	var t := make_title(title, Palette.FS_LABEL, Palette.INK)
	col.add_child(t)
	var sub := make_body(subtitle, Palette.FS_CAPTION, Palette.INK_SOFT)
	col.add_child(sub)
	row.add_child(col)

	if not trailing.is_empty():
		var tr := make_body(trailing, Palette.FS_CAPTION, Palette.INK_SOFT, false)
		tr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(tr)
	if badge > 0:
		# An unread count, drawn as the sheets draw it: a small ruby disc.
		var count := make_title(Fa.num(badge), Palette.FS_CAPTION, Palette.SNOW)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var dot := PanelContainer.new()
		dot.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.BARE,
			Palette.RUBY_LIGHT, Palette.RUBY, Palette.R_PILL, 0.0, 8, 2))
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.add_child(count)
		row.add_child(dot)
	p.add_child(row)
	return p

## One square of an item grid: a parchment tile with a gold edge, an icon,
## and an optional count in the corner.
func make_item_slot(icon: String, count: int = 0, side: float = 72.0) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(side, side)
	var empty := icon.is_empty()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PARCHMENT,
		Palette.PARCHMENT if not empty else Palette.PARCHMENT_DIM.darkened(0.1),
		Palette.PARCHMENT_DIM, Palette.R_SM, 2.0, 4, 4))
	if not empty:
		var badge := IconRect.new(icon, side * 0.56, Palette.INK)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p.add_child(badge)
	if count > 0:
		var n := make_body(Fa.num(count), Palette.FS_CAPTION, Palette.INK, false)
		n.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		n.offset_left = -26
		n.offset_top = -22
		p.add_child(n)
	return p

## A reward chip: a medallion over its amount, as the daily-reward and
## notification panels show.
func make_reward(icon: String, amount: int, colour: Color) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	var medal := Medallion.new(icon, 54.0, false)
	medal.icon_colour = colour
	medal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(medal)
	var n := make_title(Fa.num(amount), Palette.FS_LABEL, Palette.GOLD_LIGHT)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(n)
	return col

## The toggle used in settings: a teal pill with a pale knob.
func make_toggle(on: bool) -> CheckButton:
	var c := CheckButton.new()
	c.button_pressed = on
	c.focus_mode = Control.FOCUS_ALL
	return c

## A quote or hint on parchment, as the profile sheet shows under the items.
func make_quote(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(OrnateBox.Kind.PARCHMENT,
		Palette.PARCHMENT, Palette.PARCHMENT_DIM, Palette.R_MD, 2.0,
		Palette.PAD_MD, Palette.PAD_SM))
	p.add_child(make_body(text, Palette.FS_BODY, Palette.INK))
	return p
