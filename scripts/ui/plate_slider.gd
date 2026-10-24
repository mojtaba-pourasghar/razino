class_name PlateSlider
extends HSlider
## The slider drawn over a painted one: a gold track that fills from the
## right, with a pale cyan knob. Matches the reference sheet's own slider,
## which this covers.

var _hovered: bool = false

func _ready() -> void:
	# The track and knob are drawn here, so the theme must not add its own.
	for key in ["slider", "grabber_area", "grabber_area_highlight"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	add_theme_icon_override("grabber", ImageTexture.new())
	add_theme_icon_override("grabber_highlight", ImageTexture.new())
	value_changed.connect(func(_v): queue_redraw())
	mouse_entered.connect(func():
		_hovered = true
		queue_redraw())
	mouse_exited.connect(func():
		_hovered = false
		queue_redraw())

func _draw() -> void:
	var ci := get_canvas_item()
	var h := size.y
	var track_h := maxf(h * 0.34, 6.0)
	var mid := h * 0.5
	var r := track_h * 0.5
	var ratio := float((value - min_value) / maxf(max_value - min_value, 0.001))

	# Right to left: in an RTL interface a slider fills from the right, and
	# the reference sheet draws it that way too.
	var full := Rect2(0.0, mid - r, size.x, track_h)
	_rounded(ci, full, r, PlateControls.TRACK_EMPTY)
	var filled_w := size.x * ratio
	_rounded(ci, Rect2(size.x - filled_w, mid - r, filled_w, track_h), r,
		PlateControls.TRACK_FILLED)
	_outline(ci, full, r, PlateControls.TRACK_EDGE, maxf(h * 0.04, 1.5))

	var knob_x := size.x - filled_w
	var knob_r := h * 0.42
	CI.circle(ci, Vector2(knob_x, mid), knob_r, PlateControls.KNOB_EDGE)
	CI.circle(ci, Vector2(knob_x, mid), knob_r - maxf(h * 0.06, 1.5), PlateControls.KNOB)
	if has_focus() or _hovered:
		CI.arc(ci, Vector2(knob_x, mid), knob_r + 2.0, 0.0, TAU, Palette.SNOW, 2.0)

static func _points(rect: Rect2, radius: float) -> PackedVector2Array:
	radius = clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	for corner in [
		[rect.position + Vector2(radius, radius), PI, PI * 1.5],
		[rect.position + Vector2(rect.size.x - radius, radius), PI * 1.5, TAU],
		[rect.position + Vector2(rect.size.x - radius, rect.size.y - radius), 0.0, PI * 0.5],
		[rect.position + Vector2(radius, rect.size.y - radius), PI * 0.5, PI],
	]:
		var centre: Vector2 = corner[0]
		var a0: float = corner[1]
		var a1: float = corner[2]
		for i in 7:
			var a := a0 + (a1 - a0) * float(i) / 6.0
			pts.append(centre + Vector2(cos(a), sin(a)) * radius)
	return pts

static func _rounded(ci: RID, rect: Rect2, radius: float, colour: Color) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 0.0:
		return
	CI.poly(ci, _points(rect, radius), colour)

static func _outline(ci: RID, rect: Rect2, radius: float, colour: Color, width: float) -> void:
	var pts := _points(rect, radius)
	pts.append(pts[0])
	CI.polyline(ci, pts, colour, width)
