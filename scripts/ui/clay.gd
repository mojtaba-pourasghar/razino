class_name Clay
extends RefCounted
## Razino's one visual language: claymorphism.
##
## Chosen, not invented. The ui-ux-pro-max design database was asked for a
## style for a playful children's mobile game and returned claymorphism —
## "best for educational apps, children's apps, casual games" — with an exact
## specification, which is in `SPEC` below. Three earlier attempts at this
## interface were designed from my own taste and all three were rejected:
## an ornate gold frame, a carved metal one, and a flat outlined one. The
## difference here is that the numbers come from somewhere.
##
## What makes a surface read as clay, and all of it is required:
##
##   · thick border, 3–4px, in a darker shade of the surface's OWN colour
##   · generous radius, 16–24px, on everything
##   · TWO shadows: a soft outer drop below, and an inner highlight at the
##     top inside edge. One without the other reads as flat or as glass
##   · chunky proportions — nothing thin, nothing sharp
##   · a soft press that squashes rather than dims
##
## One deliberate departure from the database entry: it specifies a pastel
## palette, and Razino is a mystery. Pastel would make it gentle, and the
## brief is "exciting". So the FORM is claymorphism exactly, and the colour
## stays Razino's own saturated navy, teal and gold. Form and palette are
## separate decisions and only the form was prescribed.

## The numbers, kept together so they cannot drift apart across files.
const RADIUS := 20.0
const RADIUS_SM := 14.0
const RADIUS_PILL := 999.0
const BORDER := 4.0
const LIFT := 7.0          ## how far the outer shadow falls
const PRESS := 4.0         ## how far a pressed surface sinks
const TOUCH_MIN := 48.0    ## Android's minimum, from the UX database
const TOUCH_GAP := 8.0

# — surfaces ——————————————————————————————————————————————

## One clay surface: outer shadow, body, inner top highlight, thick border.
static func surface(ci: RID, rect: Rect2, radius: float = RADIUS,
		colour: Color = Palette.PANEL, pressed: bool = false) -> void:
	var body := rect
	if pressed:
		# A pressed surface sinks into its own shadow instead of dimming.
		# Dimming is what a flat style does; clay has somewhere to go.
		body.position.y += PRESS
		body.size.y -= PRESS
	else:
		_blob(ci, Rect2(rect.position + Vector2(0, LIFT), rect.size), radius,
			Color(0, 0, 0, 0.30))

	_blob(ci, body, radius, colour)
	_inner_top(ci, body, radius, colour)
	_inner_bottom(ci, body, radius, colour)
	_border(ci, body, radius, colour.darkened(0.42))

## A raised surface with a lit face — what a button is made of.
static func button(ci: RID, rect: Rect2, radius: float = RADIUS,
		colour: Color = Palette.ACTION, pressed: bool = false) -> void:
	surface(ci, rect, radius, colour, pressed)
	if pressed:
		return
	# The glossy cap across the top third that makes clay look squeezable.
	var cap := rect.grow(-BORDER * 1.6)
	cap.size.y *= 0.42
	if cap.size.x > 6.0 and cap.size.y > 4.0:
		_blob(ci, cap, minf(radius * 0.8, cap.size.y * 0.5),
			Color(1, 1, 1, 0.16))

## An inset: the hole a meter or a slot sits in. Same two shadows, inverted.
static func well(ci: RID, rect: Rect2, radius: float = RADIUS_SM,
		colour: Color = Palette.NIGHT) -> void:
	_blob(ci, rect, radius, colour)
	# Shadow at the top inside, light at the bottom — the opposite of a
	# raised surface, which is the whole cue that this is a hole.
	_inner_bottom(ci, rect, radius, colour.lightened(0.22))
	_inner_top(ci, rect, radius, colour.darkened(0.5))
	_border(ci, rect, radius, colour.darkened(0.3))

## A disc — avatars, icon buttons, coins.
static func disc(ci: RID, centre: Vector2, radius: float,
		colour: Color = Palette.PANEL, pressed: bool = false) -> void:
	var c := centre
	if pressed:
		c.y += PRESS
	else:
		CI.circle(ci, centre + Vector2(0, LIFT), radius, Color(0, 0, 0, 0.30))
	CI.circle(ci, c, radius, colour)
	CI.circle(ci, c - Vector2(0, radius * 0.14), radius * 0.86,
		colour.lightened(0.16))
	CI.circle(ci, c + Vector2(0, radius * 0.06), radius * 0.80, colour)
	CI.arc(ci, c, radius - BORDER * 0.5, 0.0, TAU, colour.darkened(0.42),
		BORDER, 48)

## A progress bar: a well with a clay pill inside it.
static func meter(ci: RID, rect: Rect2, ratio: float,
		colour: Color = Palette.TEAL) -> void:
	well(ci, rect, rect.size.y * 0.5, Palette.NIGHT)
	var done := clampf(ratio, 0.0, 1.0)
	if done <= 0.0:
		return
	var bar := rect.grow(-BORDER)
	bar.size.x = maxf(bar.size.y, bar.size.x * done)
	var r := bar.size.y * 0.5
	_blob(ci, bar, r, colour)
	var lit := bar.grow(-2.0)
	lit.size.y *= 0.46
	if lit.size.x > 4.0 and lit.size.y > 2.0:
		_blob(ci, lit, minf(r, lit.size.y * 0.5), colour.lightened(0.30))

## A plaque: a clay pill for a title or a label.
static func plaque(ci: RID, rect: Rect2, colour: Color = Palette.GOLD) -> void:
	surface(ci, rect, minf(RADIUS, rect.size.y * 0.5), colour)

# — plumbing ———————————————————————————————————————————————

static func _blob(ci: RID, rect: Rect2, radius: float, colour: Color) -> void:
	CI.poly(ci, ring(rect, radius), colour)

static func _border(ci: RID, rect: Rect2, radius: float,
		colour: Color) -> void:
	var pts := ring(rect.grow(-BORDER * 0.5), maxf(radius - BORDER * 0.5, 1.0))
	pts.append(pts[0])
	CI.polyline(ci, pts, colour, BORDER)

## The soft light inside the top edge. Drawn as a few stacked slices rather
## than a blur, because RenderingServer has no blur and at this softness the
## difference is not visible.
static func _inner_top(ci: RID, rect: Rect2, radius: float,
		colour: Color) -> void:
	var steps := 7
	var depth := minf(rect.size.y * 0.30, 26.0)
	for i in steps:
		var t := float(i) / float(steps - 1)
		var slice := rect.grow(-BORDER - depth * t * 0.35)
		slice.size.y = depth * (1.0 - t) * 0.6 + 2.0
		if slice.size.x <= 2.0 or slice.size.y <= 1.0:
			continue
		_blob(ci, slice, minf(radius, slice.size.y * 0.5),
			Color(colour.lightened(0.42).r, colour.lightened(0.42).g,
				colour.lightened(0.42).b, 0.13))

## The soft shadow inside the bottom edge, which is the half of the pair
## that makes the surface look thick rather than printed.
static func _inner_bottom(ci: RID, rect: Rect2, radius: float,
		colour: Color) -> void:
	var steps := 6
	var depth := minf(rect.size.y * 0.26, 22.0)
	for i in steps:
		var t := float(i) / float(steps - 1)
		var h := depth * (1.0 - t) * 0.6 + 2.0
		var slice := rect.grow(-BORDER - depth * t * 0.3)
		slice.position.y = slice.end.y - h
		slice.size.y = h
		if slice.size.x <= 2.0 or slice.size.y <= 1.0:
			continue
		_blob(ci, slice, minf(radius, slice.size.y * 0.5),
			Color(0, 0, 0, 0.10))

static func ring(rect: Rect2, radius: float) -> PackedVector2Array:
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
