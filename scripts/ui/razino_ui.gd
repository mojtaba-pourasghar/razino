class_name RazinoUI
extends RefCounted
## Razino's surfaces, drawn to docs/DESIGN.md.
##
## Every number here was sampled from `assets/art/reference/ui_kit.webp`
## rather than chosen. Four visual systems came before this one — an ornate
## gold frame, a carved metal one, a flat outlined one and claymorphism —
## and every one of them was designed from taste and rejected. The approved
## sheets are the specification now; when this file and the sheet disagree,
## the sheet is right and this file is the bug.
##
## What the sheets actually do, and all of it matters:
##
##   · a panel is dark navy with a 1.5px STEEL hairline, not a gold frame
##   · its only ornament is a short GOLD BRACKET at each corner
##   · gradients exist but are nearly invisible — a few per cent, top to
##     bottom. Flat fills read as paper; strong gradients read as plastic
##   · GOLD IS THE ACTION. Exactly one thing per screen is filled with it,
##     and it carries an outer glow. That glow is what makes it primary
##   · nothing is embossed, bevelled, outlined in black or thickly bordered

const RADIUS := 16.0
const RADIUS_BUTTON := 12.0
const RADIUS_SLOT := 10.0
const HAIRLINE := 1.5
const BRACKET := 18.0      ## how far a corner bracket runs along each edge
const TOUCH_MIN := 48.0    ## Android's minimum, from the UX database
const TOUCH_GAP := 8.0

# — surfaces ——————————————————————————————————————————————

## A panel: dark body, barely-there gradient, steel hairline, gold brackets.
static func panel(ci: RID, rect: Rect2, radius: float = RADIUS,
		fill: Color = Palette.PANEL_DEEP, brackets_: bool = true) -> void:
	_gradient(ci, rect, radius, fill.lightened(0.08), fill)
	_hairline(ci, rect, radius, Palette.PANEL_EDGE, HAIRLINE)
	if brackets_:
		brackets(ci, rect, radius)

## The short gold corner brackets. They stop well before the middle of any
## edge — the sheets never run ornament along a whole side, which is what
## keeps a screen of eight panels from reading as a wall of gold.
static func brackets(ci: RID, rect: Rect2, radius: float,
		colour: Color = Palette.GOLD_DEEP) -> void:
	var run := minf(BRACKET, minf(rect.size.x, rect.size.y) * 0.28)
	if run < 6.0:
		return
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	for corner: Array in [
		[rect.position, Vector2(1, 0), Vector2(0, 1)],
		[Vector2(rect.end.x, rect.position.y), Vector2(-1, 0), Vector2(0, 1)],
		[Vector2(rect.position.x, rect.end.y), Vector2(1, 0), Vector2(0, -1)],
		[rect.end, Vector2(-1, 0), Vector2(0, -1)],
	]:
		var c: Vector2 = corner[0]
		var ax: Vector2 = corner[1]
		var ay: Vector2 = corner[2]
		CI.polyline(ci, PackedVector2Array([c + ax * r + ax * run, c + ax * r]),
			colour, 2.4)
		CI.polyline(ci, PackedVector2Array([c + ay * r, c + ay * r + ay * run]),
			colour, 2.4)

## A button. `primary` is the one gold thing on the screen; everything else
## is a dark surface with the same steel hairline as a panel.
static func button(ci: RID, rect: Rect2, primary: bool = false,
		pressed: bool = false, hovered: bool = false) -> void:
	var body := rect
	if pressed:
		# A small inward nudge rather than a colour change: the sheets have
		# no pressed state to copy, and moving is the quietest cue that
		# still reads on a phone held at arm's length.
		body = rect.grow(-1.5)

	if primary:
		glow(ci, body, RADIUS_BUTTON, Palette.GOLD_BRIGHT, 0.26)
		var top := Palette.ACTION_LIGHT
		var bottom := Palette.ACTION_DEEP
		if pressed:
			top = Palette.ACTION_DEEP
			bottom = Palette.ACTION_DEEP.darkened(0.15)
		elif hovered:
			top = Palette.ACTION_LIGHT.lightened(0.10)
		_gradient(ci, body, RADIUS_BUTTON, top, bottom)
		_hairline(ci, body, RADIUS_BUTTON, Palette.GOLD_DEEP, 2.0)
		return

	glow(ci, body, RADIUS_BUTTON, Palette.PANEL_EDGE, 0.10)
	var face := Palette.PANEL.lightened(0.10) if hovered else Palette.PANEL
	_gradient(ci, body, RADIUS_BUTTON, face.lightened(0.12), face.darkened(0.18))
	_hairline(ci, body, RADIUS_BUTTON, Palette.PANEL_EDGE, HAIRLINE)

## An item slot: a small square well with a hairline and nothing else.
static func slot(ci: RID, rect: Rect2, filled: bool = false) -> void:
	var face := Palette.PANEL if filled else Palette.PANEL_DEEP
	_gradient(ci, rect, RADIUS_SLOT, face.lightened(0.10), face.darkened(0.12))
	_hairline(ci, rect, RADIUS_SLOT, Palette.PANEL_EDGE, 1.2)

## A bar. The track is almost black; the fill is the role's own colour.
static func bar(ci: RID, rect: Rect2, ratio: float,
		colour: Color = Palette.BLUE) -> void:
	var radius := rect.size.y * 0.5
	_fill(ci, rect, radius, Palette.NIGHT)
	_hairline(ci, rect, radius, Palette.PANEL_EDGE, 1.2)
	var done := clampf(ratio, 0.0, 1.0)
	if done <= 0.0:
		return
	var full := rect.grow(-2.5)
	full.size.x = maxf(full.size.y, full.size.x * done)
	_gradient(ci, full, full.size.y * 0.5,
		colour.lightened(0.26), colour.darkened(0.10))

## A round portrait or icon frame.
static func disc(ci: RID, centre: Vector2, radius: float,
		fill: Color = Palette.PANEL_DEEP, gold: bool = false) -> void:
	CI.circle(ci, centre, radius, fill)
	CI.circle(ci, centre - Vector2(0, radius * 0.2), radius * 0.92,
		fill.lightened(0.08))
	CI.circle(ci, centre, radius * 0.88, fill)
	CI.arc(ci, centre, radius - 1.0, 0.0, TAU,
		Palette.GOLD_DEEP if gold else Palette.PANEL_EDGE, 2.0, 48)

## The parchment the sheets reserve for dialogue, and only dialogue.
static func parchment(ci: RID, rect: Rect2, radius: float = 14.0) -> void:
	_gradient(ci, rect, radius, Palette.PARCHMENT.lightened(0.06),
		Palette.PARCHMENT.darkened(0.08))
	_hairline(ci, rect, radius, Palette.GOLD_DEEP, 2.0)
	brackets(ci, rect, radius, Palette.GOLD_DEEP)

## The soft outer light around a primary button. Drawn as a few expanding
## rounded rings; RenderingServer has no blur and at this softness nothing
## can tell the difference.
static func glow(ci: RID, rect: Rect2, radius: float, colour: Color,
		strength: float) -> void:
	for i in 6:
		var t := float(i) / 5.0
		var ring := rect.grow(2.0 + t * 9.0)
		CI.poly(ci, _ring(ring, radius + 2.0 + t * 9.0),
			Color(colour.r, colour.g, colour.b, strength * (1.0 - t) * 0.30))

# — plumbing ———————————————————————————————————————————————

static func _fill(ci: RID, rect: Rect2, radius: float, colour: Color) -> void:
	CI.poly(ci, _ring(rect, radius), colour)

## A vertical ramp, drawn as horizontal slices. The sheets' gradients are a
## few per cent across the whole height, so the slice count only has to beat
## what the eye can band at that contrast.
static func _gradient(ci: RID, rect: Rect2, radius: float, top: Color,
		bottom: Color) -> void:
	_fill(ci, rect, radius, top)
	var bands := 20
	for i in bands:
		var t := float(i) / float(bands - 1)
		var y := rect.position.y + rect.size.y * t
		var h := rect.size.y / float(bands) + 1.0
		# Pulled in near the rounded ends so a slice never pokes out of the
		# corner it is filling.
		var edge := maxf(0.0, absf(t - 0.5) * 2.0 - 0.70) / 0.30
		var inset := radius * edge * 0.95
		CI.rect(ci, Rect2(rect.position.x + inset, y,
			maxf(0.0, rect.size.x - inset * 2.0), h), top.lerp(bottom, t))

static func _hairline(ci: RID, rect: Rect2, radius: float, colour: Color,
		width: float) -> void:
	var pts := _ring(rect.grow(-width * 0.5), maxf(radius - width * 0.5, 1.0))
	pts.append(pts[0])
	CI.polyline(ci, pts, colour, width)

static func _ring(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	for corner in 4:
		var centre: Vector2
		var start: float
		match corner:
			0: centre = rect.position + Vector2(r, r); start = PI
			1: centre = Vector2(rect.end.x - r, rect.position.y + r); start = PI * 1.5
			2: centre = rect.end - Vector2(r, r); start = 0.0
			_: centre = Vector2(rect.position.x + r, rect.end.y - r); start = PI * 0.5
		for i in 8:
			var a := start + (PI * 0.5) * float(i) / 7.0
			pts.append(centre + Vector2(cos(a), sin(a)) * r)
	return pts
