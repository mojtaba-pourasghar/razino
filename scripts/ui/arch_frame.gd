class_name ArchFrame
extends Control
## The pointed-arch window the approved direction puts its artwork inside.
##
## It is the one shape that makes the direction recognisable, and nothing
## else in the kit can stand in for it: a rectangle with the same palette
## reads as a generic dark theme, which is exactly what the first pass at
## this direction produced.
##
## The picture is not placed behind a cut-out. It is drawn AS the arch: the
## shape is built as one polygon and the texture is mapped onto it, so there
## is no mask, no extra draw pass and no seam where a cut-out would meet the
## frame. The rim is then stroked along the same points, which is why the
## rim and the picture can never drift apart by a pixel.

## How much of the height the pointed head takes.
const HEAD := 0.42
## Points along each side of the head. Enough that the curve is smooth at a
## tablet's size without making the polygon expensive to rebuild on resize.
const STEPS := 24

var texture: Texture2D = null:
	set(value):
		texture = value
		queue_redraw()

## Drawn when there is no texture yet, so the composition still reads.
var empty_fill: Color = Palette.PANEL_DEEP

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	resized.connect(queue_redraw)

## The outline, clockwise from the bottom left.
##
## Each side of the head is one cubic curve from the springing line to the
## point. Two circular arcs were tried first, as a real two-centred arch is
## built, and the angle sweeps ran the long way round so the polygon crossed
## itself and would not triangulate. A curve cannot do that: it stays inside
## the box its control points make.
##
## It has to be a cubic, not a quadratic. A quadratic can only control one
## tangent, and with its handle on the top corner both halves arrived at the
## apex running horizontally, so they met smoothly and the head came out as
## a dome. The second handle sits below and inside the apex, so each side is
## still climbing when it gets there and the two meet at an angle.
func _outline() -> PackedVector2Array:
	var w := size.x
	var h := size.y
	var spring := h * HEAD
	var apex := Vector2(w * 0.5, 0.0)
	var pts := PackedVector2Array()
	pts.append(Vector2(0.0, h))
	pts.append(Vector2(0.0, spring))
	_curve(pts, Vector2(0.0, spring), Vector2(0.0, spring * 0.12),
		Vector2(w * 0.40, spring * 0.34), apex)
	_curve(pts, apex, Vector2(w * 0.60, spring * 0.34),
		Vector2(w, spring * 0.12), Vector2(w, spring))
	pts.append(Vector2(w, h))
	return pts

static func _curve(into: PackedVector2Array, a: Vector2, c1: Vector2,
		c2: Vector2, b: Vector2) -> void:
	for i in range(1, STEPS + 1):
		var t := float(i) / float(STEPS)
		var u := 1.0 - t
		into.append(a * (u * u * u) + c1 * (3.0 * u * u * t)
			+ c2 * (3.0 * u * t * t) + b * (t * t * t))

func _draw() -> void:
	var pts := _outline()
	if pts.size() < 3:
		return
	if texture != null:
		draw_colored_polygon(pts, Color.WHITE, _uvs(pts), texture)
	else:
		draw_colored_polygon(pts, empty_fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	# Two strokes, not one: a bronze band seats the window in the wall and a
	# thin teal line inside it is what the rest of the kit edges every
	# surface with, so the arch belongs to the same set as the panels.
	draw_polyline(closed, Palette.GOLD_DEEP, 7.0, true)
	draw_polyline(closed, Palette.GOLD_BRIGHT, 3.0, true)
	draw_polyline(closed, Palette.PANEL_EDGE, 1.5, true)

## Texture coordinates that fill the arch the way a background fills a
## screen: scaled to cover, centred, and cropped by the shape rather than
## squashed to its bounding box.
func _uvs(pts: PackedVector2Array) -> PackedVector2Array:
	var tex := texture.get_size()
	if tex.x <= 0.0 or tex.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return PackedVector2Array()
	var scale := maxf(size.x / tex.x, size.y / tex.y)
	var shown := tex * scale
	var offset := (shown - size) * 0.5
	var uvs := PackedVector2Array()
	for p: Vector2 in pts:
		# Clamped, so a point that lands a hair outside the picture samples
		# its edge instead of leaving a black band along the sill.
		uvs.append(Vector2(
			clampf((p.x + offset.x) / shown.x, 0.0, 1.0),
			clampf((p.y + offset.y) / shown.y, 0.0, 1.0)))
	return uvs
