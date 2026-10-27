class_name FiligreeBox
extends StyleBox
## A StyleBox that draws the sheets' chrome, so ordinary Controls get it.
##
## Everything Filigree knows how to draw, a PanelContainer or a Button can
## now wear. Drawn rather than a nine-patch for the reason the first pass
## learned the hard way: a painted ornament's corner draws at its source
## size, so the same plate that looks right on a full screen panel crumples
## into unreadable scrollwork inside a 58-pixel button.

enum Kind { PANEL, WELL, PLAQUE, ACTION, GHOST }

@export var kind: Kind = Kind.PANEL
@export var tint: Color = Palette.ACTION
@export var fill: Color = Palette.PANEL_DEEP
@export var radius: float = 18.0
@export var pressed: bool = false
## Panels only. The outermost frame of a screen carries ivy; inner panels
## must not, or the screen turns into a hedge.
@export var ivy: bool = false

static func make(kind_: Kind, radius_: float = 18.0,
		h_pad: int = Palette.PAD_MD, v_pad: int = Palette.PAD_SM) -> FiligreeBox:
	var box := FiligreeBox.new()
	box.kind = kind_
	box.radius = radius_
	box.content_margin_left = h_pad
	box.content_margin_right = h_pad
	box.content_margin_top = v_pad
	box.content_margin_bottom = v_pad
	return box

func with_fill(colour: Color) -> FiligreeBox:
	fill = colour
	return self

func with_tint(colour: Color) -> FiligreeBox:
	tint = colour
	return self

func with_ivy() -> FiligreeBox:
	ivy = true
	return self

func as_pressed() -> FiligreeBox:
	var copy := duplicate() as FiligreeBox
	copy.pressed = true
	return copy

func _draw(ci: RID, rect: Rect2) -> void:
	match kind:
		Kind.PANEL:
			Filigree.panel(ci, rect, radius, fill)
			if ivy:
				for corner in 4:
					Filigree.ivy_corner(ci, rect, corner)
		Kind.WELL:
			# An inset row: darker than the panel it sits in, one hairline,
			# no brackets. The sheets keep brackets for panels, which is what
			# stops a list of eight rows reading as eight framed pictures.
			Filigree.panel(ci, rect, radius, Palette.NIGHT, 1.0)
		Kind.PLAQUE:
			Filigree.plaque(ci, rect, fill)
		Kind.ACTION:
			Filigree.action(ci, rect, radius, tint, pressed)
		Kind.GHOST:
			Filigree.outline(ci, rect, radius, Palette.GOLD_DEEP, 1.4)
