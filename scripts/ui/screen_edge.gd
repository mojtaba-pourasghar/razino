class_name ScreenEdge
extends Control
## The gilded border around a screen, with the leafy corner flourishes the
## approved sheets draw.
##
## The frame runs to the screen edge rather than around each widget, so it
## belongs to the shell and not to any control. Drawing it here also puts it
## above the painted art and below every button.

const INSET := 12.0
## How far the corner ornament reaches along each edge.
const CORNER := 86.0

func _draw() -> void:
	var ci := get_canvas_item()
	var r := Rect2(Vector2(INSET, INSET), size - Vector2(INSET, INSET) * 2.0)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return

	# A vignette presses the eye toward the middle, as in the sheets.
	var steps := 10
	for i in steps:
		var t := float(i) / float(steps)
		var band := INSET + t * 44.0
		CI.polyline(ci, Ornate.outline_points(
			Rect2(Vector2(band, band), size - Vector2(band, band) * 2.0), Palette.R_LG),
			Color(0, 0, 0, 0.20 * (1.0 - t)), 12.0)

	# Two rails: a heavy outer band and a fine inner line, which is what
	# separates a frame from a border.
	Ornate.draw_frame(ci, r, Palette.R_LG, 5.0, false)
	Ornate._rounded_outline(ci, r.grow(-12.0), Palette.R_LG, Palette.GOLD_DEEP, 1.5)

	for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		_flourish(ci, r, corner)

## A leafy scroll at one corner: a quarter arc, three leaves along it and a
## jewel at the elbow. Drawn rather than textured so it stays crisp and
## recolours with the palette.
func _flourish(ci: RID, r: Rect2, corner: Vector2) -> void:
	var reach := minf(CORNER, minf(r.size.x, r.size.y) * 0.3)
	var origin := r.position + Vector2(r.size.x * corner.x, r.size.y * corner.y)
	var sx := 1.0 if corner.x < 0.5 else -1.0
	var sy := 1.0 if corner.y < 0.5 else -1.0
	var elbow := origin + Vector2(reach * 0.34 * sx, reach * 0.34 * sy)

	# The scroll itself.
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var t := float(i) / float(n)
		var a := PI + t * PI * 0.5
		pts.push_back(elbow + Vector2(cos(a) * sx, sin(a) * sy) * reach * 0.34)
	CI.polyline(ci, pts, Palette.GOLD_DEEP, 4.0)
	CI.polyline(ci, pts, Palette.GOLD_BRIGHT, 2.0)

	# Leaves along the scroll, each a small filled almond.
	for t: float in [0.18, 0.5, 0.82]:
		var a: float = PI + t * PI * 0.5
		var base := elbow + Vector2(cos(a) * sx, sin(a) * sy) * reach * 0.34
		var out := Vector2(cos(a + PI * 0.5) * sx, sin(a + PI * 0.5) * sy)
		var side := Vector2(-out.y, out.x)
		CI.poly(ci, PackedVector2Array([
			base, base + out * 13.0 + side * 6.0,
			base + out * 20.0, base + out * 13.0 - side * 6.0,
		]), Palette.GOLD)

	# A jewel at the elbow, and the two short rails that tie it to the frame.
	CI.circle(ci, elbow, 7.0, Palette.GOLD_DEEP)
	CI.circle(ci, elbow, 5.0, Palette.GOLD_BRIGHT)
	CI.circle(ci, elbow, 2.5, Palette.ACTION_LIGHT)
	CI.line(ci, origin + Vector2(0, reach * 0.34 * sy),
		origin + Vector2(0, reach * sy), Palette.GOLD, 3.0)
	CI.line(ci, origin + Vector2(reach * 0.34 * sx, 0),
		origin + Vector2(reach * sx, 0), Palette.GOLD, 3.0)
