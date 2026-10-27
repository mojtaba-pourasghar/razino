class_name ClayBox
extends StyleBox
## Clay's surfaces as a StyleBox, so every Control in the game wears them.

enum Kind { SURFACE, BUTTON, WELL, PLAQUE, NONE }

@export var kind: Kind = Kind.SURFACE
@export var colour: Color = Palette.PANEL
@export var radius: float = Clay.RADIUS
@export var pressed: bool = false

static func make(kind_: Kind, colour_: Color, radius_: float = Clay.RADIUS,
		h_pad: int = 18, v_pad: int = 12) -> ClayBox:
	var box := ClayBox.new()
	box.kind = kind_
	box.colour = colour_
	box.radius = radius_
	box.content_margin_left = h_pad
	box.content_margin_right = h_pad
	box.content_margin_top = v_pad
	# Room for the surface to sink into when pressed, so the label does not
	# jump by four pixels on every tap.
	box.content_margin_bottom = v_pad + int(Clay.PRESS)
	return box

func as_pressed() -> ClayBox:
	var copy := duplicate() as ClayBox
	copy.pressed = true
	return copy

## Kept from the box this replaced, because every screen calls it. The extra
## bottom margin is clay's own: a pressed surface sinks by Clay.PRESS, and
## without the room the label jumps four pixels on every tap.
func with_margins(h: int, v: int) -> ClayBox:
	content_margin_left = h
	content_margin_right = h
	content_margin_top = v
	content_margin_bottom = v + int(Clay.PRESS)
	return self

func tinted(c: Color) -> ClayBox:
	var copy := duplicate() as ClayBox
	copy.colour = c
	return copy

func _draw(ci: RID, rect: Rect2) -> void:
	match kind:
		Kind.SURFACE: Clay.surface(ci, rect, radius, colour, pressed)
		Kind.BUTTON: Clay.button(ci, rect, radius, colour, pressed)
		Kind.WELL: Clay.well(ci, rect, radius, colour)
		Kind.PLAQUE: Clay.plaque(ci, rect, colour)
		Kind.NONE: pass
