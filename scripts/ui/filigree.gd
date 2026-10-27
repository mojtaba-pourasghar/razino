class_name Filigree
extends RefCounted
## The chrome of the approved sheets, drawn.
##
## Read off assets/art/reference/sheet_four_screens.webp rather than invented.
## The sheets do not put a heavy ornate frame around every panel — that was
## the first pass's mistake, and it made every screen read as a wall of gold
## with the content buried in it. What they actually do is much quieter and
## much better:
##
##   · a panel is dark navy with a GOLD HAIRLINE around it, one or two pixels
##   · each corner carries a small L-shaped BRACKET, a little heavier
##   · the outermost frame — and only that one — carries GREEN IVY, growing
##     over the corners and trailing along the edges
##   · a lit edge along the top of the metal, shadow along the bottom
##
## The ivy is the signature of this design. Without it the screens are a
## generic dark theme with gold lines, which is exactly what the first pass
## shipped.

# — panels ——————————————————————————————————————————————————

## A panel as the sheets draw one: dark fill, a gold hairline, a brighter
## bracket at each corner, and a soft lift along the top inside edge.
static func panel(ci: RID, rect: Rect2, radius: float = 18.0,
		fill: Color = Palette.PANEL_DEEP, hairline: float = 1.6) -> void:
	_fill(ci, rect, radius, fill)
	# A breath of light inside the top edge: the sheets light every panel
	# from above, and without it a flat fill reads as a hole, not a surface.
	_inner_light(ci, rect, radius)
	outline(ci, rect, radius, Palette.GOLD_DEEP, hairline + 1.2)
	outline(ci, rect, radius, Palette.GOLD_BRIGHT, hairline)
	brackets(ci, rect, radius)

## The L-shaped corner brackets. Short, thicker than the hairline, and
## stopping well before the middle of each side — the sheets never run
## ornament along a whole edge of an inner panel.
static func brackets(ci: RID, rect: Rect2, radius: float,
		colour: Color = Palette.GOLD_BRIGHT) -> void:
	var run := minf(minf(rect.size.x, rect.size.y) * 0.22, 34.0)
	if run < 8.0:
		return
	var w := 2.6
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.end.x
	var y1 := rect.end.y
	for corner: Array in [
		[Vector2(x0, y0), Vector2(1, 0), Vector2(0, 1)],
		[Vector2(x1, y0), Vector2(-1, 0), Vector2(0, 1)],
		[Vector2(x0, y1), Vector2(1, 0), Vector2(0, -1)],
		[Vector2(x1, y1), Vector2(-1, 0), Vector2(0, -1)],
	]:
		var c: Vector2 = corner[0]
		var ax: Vector2 = corner[1]
		var ay: Vector2 = corner[2]
		CI.polyline(ci, PackedVector2Array([
			c + ax * r + ax * run, c + ax * r,
		]), colour, w)
		CI.polyline(ci, PackedVector2Array([
			c + ay * r, c + ay * r + ay * run,
		]), colour, w)
		# The small diamond that sits in the elbow of every bracket.
		_diamond(ci, c + (ax + ay) * (r * 0.52), 4.2, colour)

## A rounded outline, used on its own for hairlines and inner rules.
static func outline(ci: RID, rect: Rect2, radius: float, colour: Color,
		width: float) -> void:
	var pts := _ring(rect, radius)
	pts.append(pts[0])
	CI.polyline(ci, pts, colour, width)

# — the outer frame ————————————————————————————————————————

## The window's own border: a double gold rule with ivy over the corners.
## Only the outermost frame gets ivy; an inner panel that grew leaves would
## turn the screen into a hedge.
static func window_frame(ci: RID, rect: Rect2) -> void:
	var r := rect.grow(-6.0)
	outline(ci, r, 26.0, Palette.GOLD_DARK, 7.0)
	outline(ci, r, 26.0, Palette.GOLD_DEEP, 5.0)
	outline(ci, r, 26.0, Palette.GOLD_BRIGHT, 2.2)
	outline(ci, r.grow(-9.0), 20.0, Palette.GOLD_DEEP, 1.4)
	for corner in 4:
		ivy_corner(ci, r, corner)

## Ivy growing out of one corner of a frame: a trailing stem with leaves,
## mirrored by corner so all four read as the same plant.
##
## Drawn from a fixed shape rather than a random one, because a corner that
## is different every launch stops being part of an identity.
static func ivy_corner(ci: RID, rect: Rect2, corner: int) -> void:
	var span := minf(minf(rect.size.x, rect.size.y) * 0.30, 190.0)
	if span < 40.0:
		return
	var origin := rect.position
	var fx := 1.0
	var fy := 1.0
	if corner == 1 or corner == 3:
		origin.x = rect.end.x
		fx = -1.0
	if corner == 2 or corner == 3:
		origin.y = rect.end.y
		fy = -1.0

	# Two stems along each edge rather than one, at different lengths and
	# opposite waves. One thin line per edge read as a scratch; the sheets
	# grow a small thicket that thins out as it leaves the corner.
	for along: int in [0, 1]:
		for strand: int in [0, 1]:
			var reach := span * (1.0 if strand == 0 else 0.62)
			var swing := (1.0 if strand == 0 else -1.0)
			var stem := PackedVector2Array()
			var steps := 18
			for i in steps + 1:
				var t := float(i) / float(steps)
				var run := reach * t
				var wave := sin(t * PI * 1.7) * reach * 0.11 * swing
				stem.append(origin + (Vector2(run * fx, wave * fy) if along == 0
					else Vector2(wave * fx, run * fy)))
			CI.polyline(ci, stem, Palette.IVY_DEEP, 4.0)
			CI.polyline(ci, stem, Palette.IVY, 2.2)
			for i in range(1, steps, 2):
				var at: Vector2 = stem[i]
				var prev: Vector2 = stem[i - 1]
				var dir := (at - prev).normalized()
				var side := Vector2(-dir.y, dir.x)
				# Leaves shrink as the stem runs away from the corner, which
				# is what makes the corner read as the root of the plant.
				var fade := 1.0 - float(i) / float(steps) * 0.55
				var leaf := reach * 0.15 * fade
				_leaf(ci, at, side * (1.0 if i % 2 == 0 else -1.0), dir, leaf)

static func _leaf(ci: RID, at: Vector2, side: Vector2, along: Vector2,
		size: float) -> void:
	# An ivy leaf: a rounded triangle with a notch, which at this size reads
	# as a leaf where a plain ellipse reads as a bead.
	var tip := at + side * size + along * size * 0.35
	var a := at + along * size * 0.30
	var b := at - along * size * 0.30
	CI.poly(ci, PackedVector2Array([a, tip, b]), Palette.IVY_DEEP)
	CI.poly(ci, PackedVector2Array([
		a.lerp(at, 0.25), tip.lerp(at, 0.18), b.lerp(at, 0.25),
	]), Palette.IVY_LIGHT)

# — pieces ————————————————————————————————————————————————

## The lozenge plaque the sheets put every title in: a long hexagon with a
## gold edge and a small diamond at each point.
static func plaque(ci: RID, rect: Rect2, fill: Color = Palette.PANEL_DEEP) -> void:
	var cut := minf(rect.size.y * 0.5, rect.size.x * 0.22)
	var pts := PackedVector2Array([
		Vector2(rect.position.x + cut, rect.position.y),
		Vector2(rect.end.x - cut, rect.position.y),
		Vector2(rect.end.x, rect.get_center().y),
		Vector2(rect.end.x - cut, rect.end.y),
		Vector2(rect.position.x + cut, rect.end.y),
		Vector2(rect.position.x, rect.get_center().y),
	])
	CI.poly(ci, pts, fill)
	var ring := pts.duplicate()
	ring.append(pts[0])
	CI.polyline(ci, ring, Palette.GOLD_DEEP, 3.4)
	CI.polyline(ci, ring, Palette.GOLD_BRIGHT, 1.8)
	_diamond(ci, Vector2(rect.position.x + cut * 0.5, rect.get_center().y), 5.0,
		Palette.GOLD_BRIGHT)
	_diamond(ci, Vector2(rect.end.x - cut * 0.5, rect.get_center().y), 5.0,
		Palette.GOLD_BRIGHT)

## A call to action: the sheets' petrol teal, lit from above, in a gold edge.
static func action(ci: RID, rect: Rect2, radius: float = 16.0,
		tint: Color = Palette.ACTION, pressed: bool = false) -> void:
	# The sheets light their buttons hard: a bright lip along the top, a deep
	# shadow at the bottom, and a thick gold edge around both. A gentle ramp
	# between two near colours came out as a flat slab, which is what the
	# first pass shipped.
	# Lit, but still the sheets' deep petrol teal. Lightening the top by
	# nearly half washed the colour out to a pale cyan and the button stopped
	# belonging to the palette.
	var top := tint.lightened(0.20)
	var bottom := tint.darkened(0.46)
	if pressed:
		top = tint.darkened(0.05)
		bottom = tint.darkened(0.58)
	_fill_gradient(ci, rect, radius, top, bottom)

	# A dark seat, the metal, then the lit edge of the metal.
	outline(ci, rect, radius, Palette.GOLD_DARK, 6.0)
	outline(ci, rect, radius, Palette.GOLD_DEEP, 4.0)
	outline(ci, rect, radius, Palette.GOLD_BRIGHT, 2.0)

	# The glass highlight across the top third, which is most of what makes
	# these read as pressable rather than painted on.
	if not pressed:
		var lip := rect.grow(-5.0)
		lip.size.y *= 0.26
		var bands := 8
		for i in bands:
			var t := float(i) / float(bands - 1)
			var band := lip
			band.position.y = lip.position.y + lip.size.y * t
			band.size.y = lip.size.y / float(bands) + 1.0
			var inset := radius * maxf(0.0, 0.6 - t) * 0.8
			CI.rect(ci, Rect2(band.position.x + inset, band.position.y,
				maxf(0.0, band.size.x - inset * 2.0), band.size.y),
				Color(1, 1, 1, 0.13 * (1.0 - t)))

## A soft glow behind an item, as the sheets put behind every gem and coin.
static func glow(ci: RID, centre: Vector2, radius: float, colour: Color) -> void:
	for i in 6:
		var t := float(i) / 6.0
		CI.circle(ci, centre, radius * (0.45 + t * 0.55),
			Color(colour.r, colour.g, colour.b, 0.055 * (1.0 - t)))

# — plumbing ———————————————————————————————————————————————

static func _fill(ci: RID, rect: Rect2, radius: float, colour: Color) -> void:
	CI.poly(ci, _ring(rect, radius), colour)

static func _fill_gradient(ci: RID, rect: Rect2, radius: float,
		top: Color, bottom: Color) -> void:
	# Banded rather than a true gradient: RenderingServer has no gradient
	# fill for an arbitrary polygon, and at this size the bands are not
	# tellable apart from a smooth ramp.
	#
	# The bands cover the whole height. An earlier version started halfway
	# down, so the top half stayed one flat colour and every button in the
	# game read as a plain slab.
	_fill(ci, rect, radius, top)
	var bands := 26
	for i in bands:
		var t := float(i) / float(bands - 1)
		var y := rect.position.y + rect.size.y * t
		var h := rect.size.y / float(bands) + 1.0
		# Pull the band in near the rounded ends so it never pokes out of
		# the corner it is filling.
		var edge := maxf(0.0, absf(t - 0.5) * 2.0 - 0.72) / 0.28
		var inset := radius * edge * 0.95
		CI.rect(ci, Rect2(rect.position.x + inset, y,
			maxf(0.0, rect.size.x - inset * 2.0), h), top.lerp(bottom, t))

static func _inner_light(ci: RID, rect: Rect2, radius: float) -> void:
	var h := minf(rect.size.y * 0.55, 86.0)
	var bands := 16
	for i in bands:
		var t := float(i) / float(bands - 1)
		var inset := radius * 0.35
		CI.rect(ci, Rect2(rect.position.x + inset,
			rect.position.y + 2.0 + h * t,
			maxf(0.0, rect.size.x - inset * 2.0), h / float(bands) + 1.0),
			Color(0.36, 0.68, 0.84, 0.10 * (1.0 - t) * (1.0 - t)))

static func _diamond(ci: RID, centre: Vector2, size: float,
		colour: Color) -> void:
	CI.poly(ci, PackedVector2Array([
		centre + Vector2(0, -size), centre + Vector2(size, 0),
		centre + Vector2(0, size), centre + Vector2(-size, 0),
	]), colour)

static func _ring(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var per := 6
	for corner in 4:
		var centre: Vector2
		var start: float
		match corner:
			0: centre = rect.position + Vector2(r, r); start = PI
			1: centre = Vector2(rect.end.x - r, rect.position.y + r); start = PI * 1.5
			2: centre = rect.end - Vector2(r, r); start = 0.0
			_: centre = Vector2(rect.position.x + r, rect.end.y - r); start = PI * 0.5
		for i in per + 1:
			var a := start + (PI * 0.5) * float(i) / float(per)
			pts.append(centre + Vector2(cos(a), sin(a)) * r)
	return pts
