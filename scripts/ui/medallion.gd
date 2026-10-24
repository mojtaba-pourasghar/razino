class_name Medallion
extends Button
## The round gold-ringed control the mockup uses everywhere.
##
## Back arrows, the gear, the home menu icons, the avatar, the hearts row,
## the settings row icons — in the reference sheet every icon sits inside one
## of these. It is a Button rather than a Control so the ones that are
## tappable behave like buttons; `interactive = false` turns it into a badge.

@export var icon_name: String = "star":
	set(value):
		icon_name = value
		queue_redraw()

@export var icon_colour: Color = Palette.GOLD_BRIGHT:
	set(value):
		icon_colour = value
		queue_redraw()

## A filled face marks the active choice, as the mockup's selected tab does.
@export var filled: bool = false:
	set(value):
		filled = value
		queue_redraw()

## A portrait drawn in place of the icon — the player's avatar.
var portrait: Texture2D = null:
	set(value):
		portrait = value
		queue_redraw()

func _init(icon_: String = "star", side: float = Palette.MEDALLION,
		interactive: bool = true) -> void:
	icon_name = icon_
	custom_minimum_size = Vector2(side, side)
	focus_mode = Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	disabled = not interactive

func _ready() -> void:
	# The face is drawn here, so the theme must not paint one underneath.
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var ci := get_canvas_item()
	var centre := size * 0.5
	var r := minf(size.x, size.y) * 0.5

	var face := Palette.BLUE if filled else Palette.PANEL
	if not disabled:
		if button_pressed:
			face = face.darkened(0.2)
		elif is_hovered():
			face = face.lightened(0.12)

	CI.circle(ci, centre, r, Palette.GOLD_DARK)
	CI.circle(ci, centre, r - 2.0, face)
	# A lit arc across the top turns the ring from a line into metal.
	CI.arc(ci, centre, r - 1.5, PI, TAU, Palette.GOLD_BRIGHT, 2.5)
	CI.arc(ci, centre, r - 1.5, 0.0, PI, Palette.GOLD_DEEP, 2.5)

	if portrait != null:
		# Clipped to the ring by drawing it as a textured circle.
		var box := Rect2(centre - Vector2(r - 4, r - 4), Vector2(r - 4, r - 4) * 2.0)
		draw_texture_rect(portrait, box, false)
	else:
		var painted := UiArt.icon(icon_name)
		if painted != null:
			var side := r * 1.15
			draw_texture_rect(painted,
				Rect2(centre - Vector2(side, side) * 0.5, Vector2(side, side)), false)
		else:
			GameIcons.draw(ci, icon_name, centre, r * 0.5, icon_colour)

	if has_focus():
		CI.arc(ci, centre, r + 2.0, 0.0, TAU, Palette.SNOW, 2.0)
