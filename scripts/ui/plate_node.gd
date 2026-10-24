class_name PlateNode
extends Button
## A live map node drawn over a painted one.
##
## The world map's plaques carry a place name and a state — «باز» or «قفل» —
## painted into the picture. Neither can be left as it is: the names are the
## artist's places rather than this game's chapters, and a painted "open" on
## a chapter the player has not reached would be a lie the moment they tap
## it. So the painted plaque becomes the frame and both lines are set live
## on top, on parchment sampled from the plaque itself.

const PARCHMENT := Color("FBDD9C")
const PARCHMENT_EDGE := Color("8A6520")
const INK := Color("2E2208")
const INK_SOFT := Color("6B5526")

@export var title: String = ""
@export var state_text: String = ""
@export var unlocked: bool = true

var _hovered: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(func():
		_hovered = true
		queue_redraw())
	mouse_exited.connect(func():
		_hovered = false
		queue_redraw())
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var ci := get_canvas_item()
	var r := Rect2(Vector2.ZERO, size)
	var radius := size.y * 0.30

	var face := PARCHMENT
	if not unlocked:
		# A locked place is drained rather than hidden, so a child can see
		# there is somewhere still to go.
		face = face.lerp(Color(0.52, 0.56, 0.60), 0.55)
	elif button_pressed:
		face = face.darkened(0.10)
	elif _hovered:
		face = face.lightened(0.08)

	PlateSlider._rounded(ci, r, radius, face)
	PlateSlider._outline(ci, r, radius, PARCHMENT_EDGE, maxf(size.y * 0.05, 2.0))
	if has_focus():
		PlateSlider._outline(ci, r.grow(3.0), radius + 3.0, Palette.SNOW, 2.0)

	var font := Style.font_bold if Style.font_bold != null else ThemeDB.fallback_font
	var ink := INK if unlocked else INK.lerp(Color(0.35, 0.38, 0.42), 0.5)

	# A chapter title is longer than the place name the plaque was painted
	# for, so the type shrinks until it fits rather than running off the
	# edge — "کتابخانهٔ هزار در" came back as "کتابخانهٔ هزار د".
	var room := size.x - (size.y * 0.52 if not unlocked else size.y * 0.18)
	var title_size := int(size.y * 0.40)
	var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	while w > room and title_size > 9:
		title_size -= 1
		w = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var centre_x := (size.x - w) * 0.5
	if not unlocked:
		# Shifted clear of the padlock rather than drawn over it.
		centre_x = (size.x - w) * 0.5 + size.y * 0.16
	draw_string(font, Vector2(centre_x, size.y * 0.46), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, ink)

	var state_size := int(size.y * 0.28)
	var sw := font.get_string_size(state_text, HORIZONTAL_ALIGNMENT_LEFT, -1, state_size).x
	draw_string(font, Vector2((size.x - sw) * 0.5, size.y * 0.86), state_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, state_size, INK_SOFT if unlocked else ink)

	if not unlocked:
		GameIcons.draw(ci, "lock", Vector2(size.y * 0.34, size.y * 0.48),
			size.y * 0.20, INK)
