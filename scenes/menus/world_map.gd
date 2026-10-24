extends Control
## UI-05 — نقشهٔ جهان, built on the reference painting.
##
## The map, its islands, the compass rose and the gold frame are the
## approved art. Only the eight place plaques are live, because neither
## line on them can be left painted: the names are the artist's places
## rather than this game's chapters, and a painted "open" on a chapter the
## player has not reached is a lie the moment they tap it.
##
## The plaque positions were found by locating the painting's own parchment
## regions, not estimated.

## Where each painted plaque sits, in fractions of the painting, in the
## order the map reads them.
const NODES := [
	Rect2(0.760, 0.204, 0.135, 0.066),
	Rect2(0.417, 0.237, 0.141, 0.062),
	Rect2(0.230, 0.344, 0.121, 0.062),
	Rect2(0.700, 0.361, 0.128, 0.062),
	Rect2(0.439, 0.494, 0.129, 0.065),
	Rect2(0.140, 0.532, 0.130, 0.062),
	Rect2(0.755, 0.629, 0.130, 0.062),
	Rect2(0.326, 0.707, 0.131, 0.062),
]

const SPOTS := {
	"title": Rect2(0.045, 0.025, 0.200, 0.065),
	"gear":  Rect2(0.930, 0.028, 0.050, 0.075),
	"back":  Rect2(0.030, 0.890, 0.180, 0.070),
}

var _plate: ScreenPlate

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Style.attach(self)
	_plate = ScreenPlate.new()
	add_child(_plate)
	_plate.plate = load("res://assets/art/screens/worldmap.png")
	_build()

func _build() -> void:
	# The map shows as many places as it has plaques; the chapters fill
	# them in order, so a map painted with eight is not asked for ten.
	var chapters := ContentManager.chapter_ids()
	for i in NODES.size():
		if i >= chapters.size():
			break
		var chapter_id := String(chapters[i])
		var entry := ContentManager.catalog_entry(chapter_id)
		var open := GameState.is_chapter_unlocked(chapter_id)

		var node := PlateNode.new()
		node.title = String(entry.get("title", chapter_id))
		node.unlocked = open
		node.state_text = _state_of(chapter_id, open)
		node.disabled = not open
		node.pressed.connect(func():
			AudioManager.play_sfx("SFX_UI_TAP")
			Router.go("UI-10", {"chapter_id": chapter_id}))
		_plate.place(node, NODES[i])

	var gear := PlateControls.hotspot("تنظیمات")
	gear.pressed.connect(func(): Router.go("UI-13"))
	_plate.place(gear, SPOTS["gear"])

	var back := PlateControls.hotspot("بازگشت")
	back.pressed.connect(func(): Router.go("UI-04"))
	_plate.place(back, SPOTS["back"])

## What the second line of a plaque says. A chapter the player is part way
## through says so, because "باز" on a chapter half finished tells them
## nothing they did not know.
func _state_of(chapter_id: String, open: bool) -> String:
	if not open:
		return "قفل"
	if GameState.is_chapter_complete(chapter_id):
		return "تمام شد"
	var entry := ContentManager.catalog_entry(chapter_id)
	var percent := GameState.chapter_percent(chapter_id, int(entry.get("scene_count", 1)))
	if percent > 0.0:
		return Fa.percent(percent)
	return "باز"
