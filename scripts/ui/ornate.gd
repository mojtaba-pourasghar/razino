class_name Ornate
extends RefCounted
## The gilded frame language, drawn rather than textured.
##
## Every panel, button and badge in the game is edged with the same metal. It
## is drawn in code instead of being a nine-patch image for three reasons:
## it is crisp at any resolution, it costs nothing to ship, and an AI image
## model cannot be trusted to keep a border consistent across sixteen screens
## — or to keep invented Latin text out of it.

## Draws the gilded edge of a panel: a dark seating line, the metal body with
## a lit top and shadowed bottom, a fine inner line, and corner studs.
static func draw_frame(ci: RID, rect: Rect2, radius: float = Palette.R_MD,
		width: float = Palette.FRAME_W, studs: bool = true) -> void:
	var r := rect
	# Seat the metal on a dark line so it never floats on the panel.
	_rounded_outline(ci, r.grow(1.0), radius + 1.0, Palette.GOLD_DARK, width + 2.0)
	# The metal body.
	_rounded_outline(ci, r, radius, Palette.GOLD, width)
	# Lit edge along the top, shadow along the bottom — this is what turns a
	# flat stroke into something that reads as metal.
	_arc_band(ci, r, radius, PI, TAU, Palette.GOLD_BRIGHT, width * 0.45, -width * 0.22)
	_arc_band(ci, r, radius, 0.0, PI, Palette.GOLD_DEEP, width * 0.45, width * 0.22)
	# A fine inner line, set in, gives the frame depth.
	_rounded_outline(ci, r.grow(-width * 1.6), maxf(radius - width * 1.6, 2.0),
		Palette.GOLD_DEEP, Palette.FRAME_INNER_W)
	if studs:
		draw_corner_studs(ci, r, radius)

## Small gold diamonds at the corners — the detail that reads as "ornate"
## at a glance without costing a texture.
static func draw_corner_studs(ci: RID, rect: Rect2, radius: float) -> void:
	var inset := radius * 0.62
	for p in [
		rect.position + Vector2(inset, inset),
		rect.position + Vector2(rect.size.x - inset, inset),
		rect.position + Vector2(inset, rect.size.y - inset),
		rect.position + Vector2(rect.size.x - inset, rect.size.y - inset),
	]:
		_diamond(ci, p, 5.0, Palette.GOLD_BRIGHT, Palette.GOLD_DEEP)

## A vertical sheen across a filled shape, so panels are never flat colour.
static func draw_panel_fill(ci: RID, rect: Rect2, radius: float,
		top: Color, bottom: Color) -> void:
	var steps := 24
	for i in steps:
		var t := float(i) / float(steps - 1)
		var band := Rect2(rect.position + Vector2(0, rect.size.y * t),
			Vector2(rect.size.x, rect.size.y / float(steps) + 1.0))
		# Clip the sheen to the rounded silhouette by insetting the end bands.
		var inset := 0.0
		if t < 0.08:
			inset = radius * (1.0 - t / 0.08) * 0.45
		elif t > 0.92:
			inset = radius * ((t - 0.92) / 0.08) * 0.45
		band.position.x += inset
		band.size.x -= inset * 2.0
		CI.rect(ci, band, top.lerp(bottom, t))

## A banner for screen titles: tapered gold plate with a dark centre.
static func draw_title_banner(ci: RID, rect: Rect2) -> void:
	var r := rect
	draw_panel_fill(ci, r, Palette.R_MD, Palette.PANEL_LIGHT, Palette.PANEL_DEEP)
	draw_frame(ci, r, Palette.R_MD, Palette.FRAME_W, false)
	# Flanking diamonds instead of corner studs, so a title reads as a plaque.
	var mid := r.position.y + r.size.y * 0.5
	_diamond(ci, Vector2(r.position.x + 10.0, mid), 7.0, Palette.GOLD_BRIGHT, Palette.GOLD_DEEP)
	_diamond(ci, Vector2(r.position.x + r.size.x - 10.0, mid), 7.0, Palette.GOLD_BRIGHT, Palette.GOLD_DEEP)

# — primitives ————————————————————————————————————————————

static func _rounded_outline(ci: RID, rect: Rect2, radius: float,
		colour: Color, width: float) -> void:
	radius = clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := _rounded_points(rect, radius)
	pts.append(pts[0])
	CI.polyline(ci, pts, colour, width)

## Draws part of the outline offset inward/outward, used for the lit and
## shadowed halves of the bevel.
static func _arc_band(ci: RID, rect: Rect2, radius: float, from: float, to: float,
		colour: Color, width: float, offset: float) -> void:
	var r := rect.grow(-offset)
	radius = clampf(radius - offset, 0.0, minf(r.size.x, r.size.y) * 0.5)
	var centre := r.position + r.size * 0.5
	var pts := PackedVector2Array()
	var steps := 48
	for i in steps + 1:
		var a := from + (to - from) * float(i) / float(steps)
		# Project the angle onto the rounded rectangle rather than a circle.
		var dir := Vector2(cos(a), sin(a))
		var half := r.size * 0.5 - Vector2(radius, radius)
		var p := centre + Vector2(clampf(dir.x * r.size.x, -half.x, half.x),
			clampf(dir.y * r.size.y, -half.y, half.y)) + dir * radius
		pts.append(p)
	if pts.size() > 1:
		CI.polyline(ci, pts, colour, width)

## The rounded silhouette as a point list, for callers drawing their own
## strokes along a panel edge (the screen vignette, for one).
static func outline_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var pts := _rounded_points(rect, radius)
	pts.append(pts[0])
	return pts

static func _rounded_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(radius, radius), PI, PI * 1.5],
		[rect.position + Vector2(rect.size.x - radius, radius), PI * 1.5, TAU],
		[rect.position + Vector2(rect.size.x - radius, rect.size.y - radius), 0.0, PI * 0.5],
		[rect.position + Vector2(radius, rect.size.y - radius), PI * 0.5, PI],
	]
	for corner in corners:
		var centre: Vector2 = corner[0]
		var a0: float = corner[1]
		var a1: float = corner[2]
		for i in 9:
			var a := a0 + (a1 - a0) * float(i) / 8.0
			pts.append(centre + Vector2(cos(a), sin(a)) * radius)
	return pts

static func _diamond(ci: RID, centre: Vector2, size: float,
		face: Color, edge: Color) -> void:
	var pts := PackedVector2Array([
		centre + Vector2(0, -size), centre + Vector2(size, 0),
		centre + Vector2(0, size), centre + Vector2(-size, 0),
	])
	CI.poly(ci, pts, face)
	var outline := pts
	outline.append(pts[0])
	CI.polyline(ci, outline, edge, 1.5)
