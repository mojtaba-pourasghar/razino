class_name CI
extends RefCounted
## Drawing primitives against a canvas-item RID.
##
## Everything ornate in Razino is drawn twice over: once inside a Control's
## `_draw`, and once inside a StyleBox's `_draw`. The first hands you a
## CanvasItem with convenient methods; the second hands you only a RID. So the
## frame language is written against the RID — the lowest common denominator —
## and Controls pass `get_canvas_item()`.

static func circle(ci: RID, centre: Vector2, radius: float, colour: Color) -> void:
	RenderingServer.canvas_item_add_circle(ci, centre, radius, colour)

static func rect(ci: RID, r: Rect2, colour: Color) -> void:
	RenderingServer.canvas_item_add_rect(ci, r, colour)

static func line(ci: RID, from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	RenderingServer.canvas_item_add_line(ci, from, to, colour, width, true)

static func poly(ci: RID, points: PackedVector2Array, colour: Color) -> void:
	if points.size() < 3:
		return
	var colours := PackedColorArray()
	colours.push_back(colour)
	RenderingServer.canvas_item_add_polygon(ci, points, colours)

static func polyline(ci: RID, points: PackedVector2Array, colour: Color, width: float) -> void:
	if points.size() < 2:
		return
	var colours := PackedColorArray()
	colours.push_back(colour)
	RenderingServer.canvas_item_add_polyline(ci, points, colours, width, true)

## An arc, as a polyline — RenderingServer has no arc of its own.
static func arc(ci: RID, centre: Vector2, radius: float, from: float, to: float,
		colour: Color, width: float, steps: int = 28) -> void:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var a := from + (to - from) * float(i) / float(steps)
		pts.push_back(centre + Vector2(cos(a), sin(a)) * radius)
	polyline(ci, pts, colour, width)
