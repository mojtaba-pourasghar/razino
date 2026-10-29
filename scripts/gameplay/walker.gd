class_name Walker
extends CharacterBody2D
## A character the player actually drives, with the feel of a platformer
## rather than the step-through of an adventure game.
##
## Every number here is a feel number and they were chosen together; moving
## one alone will make the character worse, not different. The three that
## matter most are the ones a player never sees and always notices:
##
##  · COYOTE — you may still jump for a moment after walking off an edge.
##    Without it a player who jumps at the exact frame they leave the ground
##    does not jump at all, and blames the game. Correctly.
##  · BUFFER — a jump pressed just before landing is remembered and fires on
##    touchdown, instead of being eaten.
##  · CUT — releasing the button early cuts the rise short, so a tap is a
##    small hop and a hold is a full jump. One button, two heights.
##
## Horizontal control is acceleration-based with a hard turn boost, so the
## character answers immediately without being frictionless.

signal landed(fall_speed: float)
signal jumped()

const RUN_SPEED := 340.0
const ACCEL := 2600.0
const FRICTION := 3200.0
## Turning the other way is faster than starting from standing: this is what
## makes the character feel eager rather than heavy.
const TURN_BOOST := 1.9

const GRAVITY := 2000.0
## Falling is faster than rising. Equal gravity both ways reads as floaty.
const FALL_GRAVITY := 2700.0
const MAX_FALL := 1400.0
const JUMP_SPEED := 760.0
const CUT := 0.42

const COYOTE := 0.10
const BUFFER := 0.12

var facing: int = 1
var _coyote: float = 0.0
var _buffer: float = 0.0
var _was_on_floor: bool = false

## Set by whatever is driving: -1, 0 or 1.
var input_x: float = 0.0
var jump_held: bool = false


func request_jump() -> void:
	_buffer = BUFFER


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		_coyote = COYOTE
	else:
		_coyote = maxf(0.0, _coyote - delta)
	_buffer = maxf(0.0, _buffer - delta)

	# — sideways —
	var want := input_x * RUN_SPEED
	if is_zero_approx(want):
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	else:
		var rate := ACCEL
		if signf(want) != signf(velocity.x) and not is_zero_approx(velocity.x):
			rate *= TURN_BOOST
		velocity.x = move_toward(velocity.x, want, rate * delta)
		facing = 1 if want > 0.0 else -1

	# — up and down —
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = -JUMP_SPEED
		_buffer = 0.0
		_coyote = 0.0
		jumped.emit()
	elif velocity.y < 0.0 and not jump_held:
		# The button was let go on the way up, so stop climbing.
		velocity.y *= CUT

	var g := GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
	velocity.y = minf(velocity.y + g * delta, MAX_FALL)

	var fall_speed := velocity.y
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		landed.emit(fall_speed)
	_was_on_floor = is_on_floor()
