class_name PlateValue
extends Control
## A live number drawn over a painted one.
##
## The painting carries a placeholder — the reference shows level 18 — so
## the patch underneath is the panel's own colour, sampled from the art, and
## the real figure is set on top of it in the game's font.

const PATCH := Color("002136")

@export var text: String = "":
	set(value):
		text = value
		queue_redraw()

@export var colour: Color = Palette.SNOW

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PATCH)
	var font := Style.font_bold if Style.font_bold != null else ThemeDB.fallback_font
	var fs := int(size.y * 0.78)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2((size.x - w) * 0.5, size.y * 0.78), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)
