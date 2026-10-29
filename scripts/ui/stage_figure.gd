class_name StageFigure
extends Control
## A cast member standing in a conversation, breathing.
##
## The dialogue stage used to place a flat painting per speaker. Nothing on
## it moved, so a conversation was two cut-outs with text under them, and a
## scene that is otherwise alive made that more obvious rather than less.
##
## This wraps the same rig the player's character uses. The figure is not
## walking, so `drive` is called with no velocity and the idle does all the
## work: a slow breath, a slower shift of weight, and the head lagging
## behind both.

## Content names a character; the rig is filed under its own name. The hero
## is the only one that differs, and only because the rig was cut before
## the cast was named.
const RIG_NAME := {"arad": "hero"}

var character_id: String = ""
var pose: String = "idle"

var _rig: RiggedFigure
var _speaking: bool = false


func _init(id: String = "") -> void:
	character_id = id
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_rig = RiggedFigure.new(RIG_NAME.get(character_id, character_id))
	add_child(_rig)
	resized.connect(_fit)
	_fit()
	set_process(true)


## How much of its box the figure fills. The rig is drawn at an exact
## height, where the painting it replaced was fitted inside its box with
## room around it; taking the whole box made every speaker a head taller
## than before and pushed the one on the end off the screen.
const FILL := 0.78


func _fit() -> void:
	if _rig == null:
		return
	_rig.height = size.y * FILL
	# The rig draws from its feet, so it is placed on the floor line of its
	# own box rather than in the middle of it.
	_rig.position = Vector2(size.x * 0.5, size.y)


func _process(delta: float) -> void:
	if _rig != null:
		_rig.drive(Vector2.ZERO, true, delta)


## Whoever is talking comes forward: brighter, and a little larger. The one
## listening is dimmed rather than greyed, so the scene still reads as two
## people in the same light.
func set_speaking(on: bool) -> void:
	if on == _speaking:
		return
	_speaking = on
	var tint := Color.WHITE if on else Color(0.72, 0.76, 0.84)
	var lift := 1.04 if on else 1.0
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate", tint, 0.25)
	if _rig != null:
		t.tween_property(_rig, "scale", Vector2(lift, lift), 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
