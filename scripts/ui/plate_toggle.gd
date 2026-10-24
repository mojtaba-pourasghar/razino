class_name PlateToggle
extends BaseButton
## The switch drawn over a painted one: a teal pill with a cream knob,
## matching the reference sheet's own toggles.

var _hovered: bool = false

func _ready() -> void:
	toggled.connect(func(_on): queue_redraw())
	mouse_entered.connect(func():
		_hovered = true
		queue_redraw())
	mouse_exited.connect(func():
		_hovered = false
		queue_redraw())

func _draw() -> void:
	var ci := get_canvas_item()
	var h := size.y
	var r := h * 0.5
	var rect := Rect2(0.0, 0.0, size.x, h)
	var face := PlateControls.TOGGLE_ON if button_pressed else PlateControls.TOGGLE_OFF
	if _hovered:
		face = face.lightened(0.12)
	PlateSlider._rounded(ci, rect, r, face)
	PlateSlider._outline(ci, rect, r, Palette.GOLD_DEEP, maxf(h * 0.06, 1.5))

	# The knob sits on the side the switch is leaning toward. In this
	# interface "on" leans right, as the reference draws it.
	var knob_r := r - maxf(h * 0.12, 2.0)
	var knob_x := (size.x - r) if button_pressed else r
	CI.circle(ci, Vector2(knob_x, r), knob_r, Palette.GOLD_DEEP)
	CI.circle(ci, Vector2(knob_x, r), knob_r - maxf(h * 0.05, 1.0), PlateControls.TOGGLE_KNOB)
	if has_focus():
		PlateSlider._outline(ci, rect.grow(2.0), r + 2.0, Palette.SNOW, 2.0)
