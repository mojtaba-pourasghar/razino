class_name LogoPlate
extends Control
## The game's title: a gold cartouche with a compass above it and «رازینو»
## across the middle.
##
## Drawn rather than painted, for one reason that is not going to change: an
## image model cannot write Persian. Every attempt produces letter-shaped
## marks that a Persian reader sees immediately as nonsense. The title has to
## be set in the real font, so the plate it sits on is drawn to match it
## rather than the other way round.

@export var title: String = "رازینو"
@export var subtitle: String = "THE ADVENTURE BEGINS"

func _init() -> void:
	custom_minimum_size = Vector2(560, 230)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var ci := get_canvas_item()
	var w := size.x
	var h := size.y
	# The cartouche sits below the compass, which overhangs its top edge.
	var oval := Rect2(w * 0.06, h * 0.16, w * 0.88, h * 0.60)
	var centre := oval.position + oval.size * 0.5
	var rx := oval.size.x * 0.5
	var ry := oval.size.y * 0.5

	_oval(ci, centre, rx + 9.0, ry + 9.0, Palette.GOLD_DARK)
	_oval(ci, centre, rx + 6.0, ry + 6.0, Palette.GOLD_DEEP)
	_oval(ci, centre, rx + 2.0, ry + 2.0, Palette.GOLD_BRIGHT)
	_oval(ci, centre, rx, ry, Palette.PANEL_DEEP)
	# A lit arc along the top of the ring turns it from an outline to metal.
	_oval_arc(ci, centre, rx + 4.0, ry + 4.0, PI, TAU, Palette.GOLD_BRIGHT, 3.0)
	_oval_arc(ci, centre, rx + 4.0, ry + 4.0, 0.0, PI, Palette.GOLD_DEEP, 3.0)

	# Star points around the rim, as the reference sheet has them.
	for i in 16:
		var a := TAU * float(i) / 16.0
		var p := centre + Vector2(cos(a) * (rx + 5.0), sin(a) * (ry + 5.0))
		GameIcons.draw(ci, "star", p, 7.0, Palette.GOLD_BRIGHT)

	for side: float in [-1.0, 1.0]:
		_scroll(ci, Vector2(centre.x + side * (rx + 4.0), centre.y), side, ry * 0.52)

	# The compass medallion, overhanging the top of the cartouche.
	var comp := Vector2(centre.x, oval.position.y)
	var cr := h * 0.15
	CI.circle(ci, comp, cr + 4.0, Palette.GOLD_DEEP)
	CI.circle(ci, comp, cr, Palette.GOLD_BRIGHT)
	CI.circle(ci, comp, cr * 0.76, Palette.ACTION_DEEP)
	GameIcons.draw(ci, "compass", comp, cr * 0.62, Palette.GOLD_BRIGHT)

	_draw_title(centre, oval)

func _draw_title(centre: Vector2, oval: Rect2) -> void:
	var font := Style.font_bold if Style.font_bold != null else ThemeDB.fallback_font
	var fs := int(oval.size.y * 0.52)
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	var baseline := centre + Vector2(-width * 0.5, fs * 0.36)
	# A dark seating outline, then the gold face, so the letters read against
	# the cartouche the way cast metal would.
	draw_string_outline(font, baseline, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		int(fs * 0.12), Palette.GOLD_DARK)
	draw_string(font, baseline, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		Palette.GOLD_BRIGHT)

	if subtitle.is_empty():
		return
	var sub_fs := int(oval.size.y * 0.16)
	var sub_w := font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_CENTER, -1, sub_fs).x
	var sub_at := Vector2(centre.x - sub_w * 0.5, oval.position.y + oval.size.y + sub_fs * 1.4)
	draw_string_outline(font, sub_at, subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs,
		int(sub_fs * 0.3), Color(0, 0, 0, 0.7))
	draw_string(font, sub_at, subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs,
		Palette.GOLD_LIGHT)

## A gold flourish at one end of the cartouche: two opposed curls and a
## diamond where they meet.
func _scroll(ci: RID, at: Vector2, side: float, reach: float) -> void:
	for turn: float in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for i in 15:
			var t := float(i) / 14.0
			var a: float = PI * 0.5 * turn + t * PI * 1.1 * turn
			var rad := reach * (1.0 - t * 0.55)
			pts.push_back(at + Vector2(cos(a) * rad * side * 0.9, sin(a) * rad))
		CI.polyline(ci, pts, Palette.GOLD_DEEP, 6.0)
		CI.polyline(ci, pts, Palette.GOLD_BRIGHT, 3.0)
	GameIcons.draw(ci, "star", at + Vector2(side * reach * 0.42, 0.0),
		reach * 0.34, Palette.GOLD_BRIGHT)

# — primitives ————————————————————————————————————————————

static func _oval_points(centre: Vector2, rx: float, ry: float,
		from: float = 0.0, to: float = TAU, steps: int = 72) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var a := from + (to - from) * float(i) / float(steps)
		pts.push_back(centre + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func _oval(ci: RID, centre: Vector2, rx: float, ry: float, colour: Color) -> void:
	CI.poly(ci, _oval_points(centre, rx, ry), colour)

static func _oval_arc(ci: RID, centre: Vector2, rx: float, ry: float,
		from: float, to: float, colour: Color, width: float) -> void:
	CI.polyline(ci, _oval_points(centre, rx, ry, from, to, 40), colour, width)
