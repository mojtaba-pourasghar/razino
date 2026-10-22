class_name ScreenEdge
extends Control
## The gilded border around the whole window, plus a vignette.
##
## The mockup's frame runs right to the screen edge rather than around each
## panel, so it belongs to the screen shell and not to any widget. Drawing it
## here also means it sits above the painted art and below every control.

const INSET := 10.0

func _draw() -> void:
	var ci := get_canvas_item()
	# A vignette presses the eye toward the middle, as in the reference sheet.
	var steps := 10
	for i in steps:
		var t := float(i) / float(steps)
		var alpha := 0.22 * (1.0 - t)
		var band := INSET + t * 46.0
		CI.polyline(ci, Ornate.outline_points(
			Rect2(Vector2(band, band), size - Vector2(band, band) * 2.0), Palette.R_LG),
			Color(0, 0, 0, alpha), 12.0)
	Ornate.draw_frame(ci, Rect2(Vector2(INSET, INSET), size - Vector2(INSET, INSET) * 2.0),
		Palette.R_LG, 4.0, true)
