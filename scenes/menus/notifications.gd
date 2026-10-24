extends Control
## UI-18 — اعلان‌ها و جوایز, built on the reference painting.
##
## The frame, the cards, the icons and the reward panel all come from
## assets/art/screens/notifications.png. Only the hit areas are live, so a
## tap on a painted card does something.
##
## The card bands were measured off the painting by finding its parchment
## regions, not estimated — a row that is two pixels out is visible the
## moment a finger lands between two cards.

const SPOTS := {
	"close":  Rect2(0.930, 0.030, 0.055, 0.080),
	"row0":   Rect2(0.045, 0.160, 0.445, 0.134),
	"row1":   Rect2(0.045, 0.304, 0.445, 0.134),
	"row2":   Rect2(0.045, 0.450, 0.445, 0.133),
	"row3":   Rect2(0.045, 0.595, 0.445, 0.133),
	"row4":   Rect2(0.045, 0.738, 0.445, 0.137),
	"claim":  Rect2(0.555, 0.735, 0.330, 0.082),
	"all":    Rect2(0.520, 0.885, 0.225, 0.072),
	"trash":  Rect2(0.882, 0.882, 0.080, 0.078),
}

var _plate: ScreenPlate

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Style.attach(self)
	_plate = ScreenPlate.new()
	add_child(_plate)
	_plate.plate = load("res://assets/art/screens/notifications.png")
	_build()

func _build() -> void:
	# The painted rows stand for, in order: the daily reward, a new quest,
	# an item found, a chapter beaten, a message. Each goes where that
	# actually lives in the game.
	var destinations := ["UI-11", "UI-10", "UI-19", "UI-10", "UI-17"]
	for i in destinations.size():
		var hot := PlateControls.hotspot()
		var target: String = destinations[i]
		hot.pressed.connect(func():
			AudioManager.play_sfx("SFX_UI_TAP")
			Router.go(target))
		_plate.place(hot, SPOTS["row%d" % i])

	var claim := PlateControls.hotspot("دریافت جایزه")
	claim.pressed.connect(_claim)
	_plate.place(claim, SPOTS["claim"])

	for spot in ["close", "all"]:
		var leave := PlateControls.hotspot()
		leave.pressed.connect(func(): Router.go("UI-04"))
		_plate.place(leave, SPOTS[spot])

	var trash := PlateControls.hotspot("پاک‌کردن همه")
	trash.pressed.connect(func(): AudioManager.play_sfx("SFX_UI_TAP"))
	_plate.place(trash, SPOTS["trash"])

func _claim() -> void:
	# The painting shows what the chest holds; this hands it over once.
	if GameState.get_flag("daily_reward_taken", false):
		AudioManager.play_sfx("SFX_UI_TAP")
		return
	GameState.coins += 500
	GameState.gems += 5
	GameState.set_flag("daily_reward_taken", true)
	AudioManager.play_sfx("SFX_UI_TAP")
	Router.go("UI-04")
