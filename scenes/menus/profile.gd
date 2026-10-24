extends Control
## UI-17 — پروفایل, built on the reference painting.
##
## The portrait, the panels, the stat rows and their Persian labels come
## from assets/art/screens/profile.png. The numbers beside them are the
## player's real ones, drawn over the painted placeholders — a profile that
## showed someone else's level would be worse than no profile at all.

const SPOTS := {
	"back":   Rect2(0.012, 0.035, 0.065, 0.100),
	"gear":   Rect2(0.898, 0.035, 0.068, 0.100),
	"edit":   Rect2(0.268, 0.398, 0.062, 0.082),
	"more":   Rect2(0.735, 0.160, 0.198, 0.075),
	"cont":   Rect2(0.388, 0.788, 0.392, 0.104),
	"tab":    Rect2(0.012, 0.888, 0.175, 0.080),
	"med0":   Rect2(0.022, 0.795, 0.074, 0.095),
	"med1":   Rect2(0.102, 0.795, 0.074, 0.095),
	"med2":   Rect2(0.182, 0.795, 0.074, 0.095),
	"med3":   Rect2(0.262, 0.795, 0.074, 0.095),
	# The painted numbers down the stat column, covered with the real ones.
	# The second row is the experience bar, which the painting draws and
	# nothing here replaces, so the rows skip it.
	"level":  Rect2(0.282, 0.492, 0.080, 0.058),
	"clues":  Rect2(0.282, 0.627, 0.080, 0.058),
	"items":  Rect2(0.282, 0.689, 0.080, 0.058),
	"done":   Rect2(0.282, 0.752, 0.080, 0.058),
}

var _plate: ScreenPlate

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Style.attach(self)
	_plate = ScreenPlate.new()
	add_child(_plate)
	_plate.plate = load("res://assets/art/screens/profile.png")
	_build()

func _build() -> void:
	var back := PlateControls.hotspot("بازگشت")
	back.pressed.connect(func(): Router.go("UI-04"))
	_plate.place(back, SPOTS["back"])

	var gear := PlateControls.hotspot("تنظیمات")
	gear.pressed.connect(func(): Router.go("UI-13"))
	_plate.place(gear, SPOTS["gear"])

	var edit := PlateControls.hotspot("تغییر ظاهر")
	edit.pressed.connect(func(): Router.go("UI-12"))
	_plate.place(edit, SPOTS["edit"])

	for spot in ["cont", "tab"]:
		var leave := PlateControls.hotspot()
		leave.pressed.connect(func(): Router.go("UI-04"))
		_plate.place(leave, SPOTS[spot])

	var more := PlateControls.hotspot("کوله‌پشتی")
	more.pressed.connect(func(): Router.go("UI-19"))
	_plate.place(more, SPOTS["more"])

	for i in 4:
		var hot := PlateControls.hotspot()
		var where: String = ["UI-19", "UI-08", "UI-11", "UI-15"][i]
		hot.pressed.connect(func(): Router.go(where))
		_plate.place(hot, SPOTS["med%d" % i])

	_value("level", Fa.num(GameState.level))
	_value("clues", Fa.num(GameState.clues.size()))
	_value("items", Fa.num(GameState.inventory.size()))
	_value("done", Fa.num(_chapters_complete()))

## Covers a painted number with the player's own, on a patch of the panel
## colour so the placeholder underneath does not show through.
func _value(spot: String, text: String) -> void:
	var patch := PlateValue.new()
	patch.text = text
	_plate.place(patch, SPOTS[spot])

func _chapters_complete() -> int:
	var n := 0
	for cid in GameState.chapter_progress.keys():
		if GameState.is_chapter_complete(String(cid)):
			n += 1
	return n
