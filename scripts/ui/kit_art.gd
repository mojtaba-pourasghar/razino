class_name KitArt
extends RefCounted
## The painted kit, loaded as it arrives.
##
## Every surface in the game is drawn by RazinoUI today. As pieces of the
## painted kit land in assets/art/kit/ they replace their drawn version one
## at a time, and anything missing keeps being drawn — a half-painted kit is
## the normal state for weeks, not a fault.
##
## Only two kinds of piece are ever painted, for the reason set out in
## content_tools/generate_ui_kit.py: a CORNER, which the engine mirrors into
## four and joins with a drawn edge, and a FACE, which is uniform and so can
## be stretched to any size. Nothing that has to stretch is ever painted
## whole.

const DIR := "res://assets/art/kit/"

static var _cache: Dictionary = {}

## A painted piece, or null when it has not arrived yet.
static func piece(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var tex: Texture2D = null
	var path := "%s%s.png" % [DIR, name]
	if ResourceLoader.exists(path):
		tex = ResourceLoader.load(path) as Texture2D
	_cache[name] = tex
	return tex

static func has(name: String) -> bool:
	return piece(name) != null

static func forget() -> void:
	_cache.clear()

## Draws a painted corner into each corner of a rect, mirrored.
##
## Mirroring is what makes the four match. A model asked for four corners
## draws four different ones and the eye catches it at once, so it is only
## ever asked for one.
static func corners(ci: RID, rect: Rect2, name: String, side: float) -> bool:
	var tex := piece(name)
	if tex == null:
		return false
	var s := minf(side, minf(rect.size.x, rect.size.y) * 0.45)
	if s < 6.0:
		return false
	# The sheet on disk already holds all four, mirrored at build time, so
	# each corner is one quarter of it drawn into its own corner.
	var half := tex.get_size() * 0.5
	var quads := [
		[Rect2(Vector2.ZERO, half), rect.position],
		[Rect2(Vector2(half.x, 0), half), Vector2(rect.end.x - s, rect.position.y)],
		[Rect2(Vector2(0, half.y), half), Vector2(rect.position.x, rect.end.y - s)],
		[Rect2(half, half), rect.end - Vector2(s, s)],
	]
	for q: Array in quads:
		var src: Rect2 = q[0]
		var at: Vector2 = q[1]
		RenderingServer.canvas_item_add_texture_rect_region(
			ci, Rect2(at, Vector2(s, s)), tex.get_rid(), src)
	return true

## Stretches a painted face across a rect. A face is uniform by construction,
## so stretching it cannot distort anything.
static func face(ci: RID, rect: Rect2, name: String) -> bool:
	var tex := piece(name)
	if tex == null:
		return false
	RenderingServer.canvas_item_add_texture_rect(ci, rect, tex.get_rid())
	return true
