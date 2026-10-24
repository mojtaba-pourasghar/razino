class_name IconRect
extends Control
## Places an icon in a layout: the painted one when it exists, the drawn
## shape when it does not.
##
## A ring makes a medallion — the form used for currency chips, stage markers
## and button adornments.

@export var icon: String = "star":
	set(value):
		icon = value
		queue_redraw()

@export var colour: Color = Palette.GOLD_BRIGHT:
	set(value):
		colour = value
		queue_redraw()

## Draws a dark disc with a gold ring behind the icon.
@export var medallion: bool = false:
	set(value):
		medallion = value
		queue_redraw()

## Whether the painted icon may stand in for the drawn one.
##
## A painted icon carries its own dark tile, which is right on a night panel
## and wrong on parchment or at the size of a star in a row — there it reads
## as a brown square with something in it. Those callers ask for the drawn
## shape, which takes the colour it is given.
@export var painted: bool = true:
	set(value):
		painted = value
		queue_redraw()

func _init(icon_: String = "star", side: float = 32.0, colour_: Color = Palette.GOLD_BRIGHT) -> void:
	icon = icon_
	colour = colour_
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var ci := get_canvas_item()
	var centre := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	if medallion:
		CI.circle(ci, centre, r, Palette.PANEL_DEEP)
		CI.arc(ci, centre, r - 1.5, 0.0, TAU, Palette.GOLD, 2.5)
		r *= 0.62
	var art := UiArt.icon(icon) if painted else null
	if art != null:
		# A painting carries its own colour; tinting it would flatten it.
		var side := r * 1.9
		draw_texture_rect(art,
			Rect2(centre - Vector2(side, side) * 0.5, Vector2(side, side)), false)
		return
	GameIcons.draw(ci, icon, centre, r * 0.92, colour)
