class_name ScreenPlate
extends Control
## A whole screen as one painting, with live controls placed on top of it.
##
## Composing a screen out of nine-patch panels can never be pixel-exact to a
## painted reference: a painted ornament stretches when the panel it frames
## changes size, and the reference was painted at one size with everything
## in one pass. So for screens whose layout does not change — settings,
## profile, the notification list — the painting IS the screen, and only the
## parts that actually move are drawn on top of it.
##
## Positions are given as fractions of the plate, not pixels, so a control
## lands on the same painted element whatever size the window is.

var plate: Texture2D:
	set(value):
		plate = value
		_art.texture = value
		queue_redraw()
		_reposition()

var _art: TextureRect
## child -> its rectangle in plate fractions
var _placed: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var fill := ColorRect.new()
	fill.color = Palette.NIGHT
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)

	_art = TextureRect.new()
	_art.texture = plate
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# The painting keeps its proportions. Stretching it to an arbitrary
	# window would skew the gold, which is the one thing this is for.
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)

	resized.connect(_reposition)
	_reposition()

## Where the painting actually sits inside this control, once letterboxed.
func plate_rect() -> Rect2:
	if plate == null or size.x <= 0.0 or size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)
	var tex := Vector2(plate.get_width(), plate.get_height())
	var scale := minf(size.x / tex.x, size.y / tex.y)
	var shown := tex * scale
	return Rect2((size - shown) * 0.5, shown)

## Converts a rectangle in plate fractions to one in this control's pixels.
func rect_of(fraction: Rect2) -> Rect2:
	var r := plate_rect()
	return Rect2(r.position + fraction.position * r.size, fraction.size * r.size)

## Puts a control over a painted element and keeps it there when the window
## changes size.
func place(control: Control, fraction: Rect2) -> void:
	if control.get_parent() != self:
		add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_placed[control] = fraction
	_apply(control, fraction)

func _reposition() -> void:
	for control: Control in _placed.keys():
		if is_instance_valid(control):
			_apply(control, _placed[control])

func _apply(control: Control, fraction: Rect2) -> void:
	var r := rect_of(fraction)
	control.position = r.position
	control.size = r.size
	control.custom_minimum_size = Vector2.ZERO

## How much bigger the painting is being shown than it was painted. Controls
## drawn on top use this so their own strokes scale with the art.
func plate_scale() -> float:
	if plate == null:
		return 1.0
	return plate_rect().size.x / float(maxi(plate.get_width(), 1))
