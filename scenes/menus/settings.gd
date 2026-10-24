extends Control
## UI-13 — تنظیمات, built on the reference painting itself.
##
## The frame, the panels, the icons and every Persian label come from
## assets/art/screens/settings.png, which is the approved design. Only what
## the player can actually change is drawn on top of it: three sliders, three
## switches, and invisible hit areas over the painted buttons.
##
## This is the right trade for this screen because none of its layout moves.
## Its labels never change, its rows never grow, and its controls sit where
## the painting puts them — so composing it out of stretchable panels bought
## nothing and cost the exact look.
##
## The content is still what GDD §12.2 requires: three independent volumes,
## plus the accessibility switches a child who is still learning needs.

## Where each live control sits, as a fraction of the painting. Measured
## against the plate, not guessed — see docs/UI_SPEC.md.
const SPOTS := {
	"close":    Rect2(0.915, 0.045, 0.060, 0.090),
	"nav0":     Rect2(0.045, 0.150, 0.285, 0.130),
	"nav1":     Rect2(0.045, 0.285, 0.285, 0.120),
	"nav2":     Rect2(0.045, 0.410, 0.285, 0.120),
	"nav3":     Rect2(0.045, 0.535, 0.285, 0.120),
	"nav4":     Rect2(0.045, 0.660, 0.285, 0.130),
	"slider0":  Rect2(0.590, 0.192, 0.250, 0.056),
	"slider1":  Rect2(0.590, 0.297, 0.250, 0.056),
	"drop":     Rect2(0.575, 0.390, 0.330, 0.100),
	"toggle0":  Rect2(0.789, 0.507, 0.124, 0.080),
	"toggle1":  Rect2(0.789, 0.612, 0.124, 0.080),
	"toggle2":  Rect2(0.789, 0.717, 0.124, 0.080),
	"save":     Rect2(0.455, 0.818, 0.285, 0.112),
}

## Which setting each painted row drives, in the order the painting draws
## them. The labels are in the art, so only the keys live here.
const ROWS := [
	{"spot": "slider0", "key": "music_volume"},
	{"spot": "slider1", "key": "sfx_volume"},
	{"spot": "toggle0", "key": "auto_advance"},
	{"spot": "toggle1", "key": "subtitles_enabled"},
	{"spot": "toggle2", "key": "reduce_motion"},
]

var _plate: ScreenPlate

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Style.attach(self)
	_plate = ScreenPlate.new()
	add_child(_plate)
	_plate.plate = load("res://assets/art/screens/settings.png")
	_build()

func _build() -> void:
	for row: Dictionary in ROWS:
		var key := String(row["key"])
		var spot := String(row["spot"])
		if spot.begins_with("slider"):
			var s := PlateControls.slider(Settings.get(key))
			s.value_changed.connect(func(v): Settings.set_value(key, v))
			_plate.place(s, SPOTS[spot])
		else:
			var t := PlateControls.toggle(bool(Settings.get(key)))
			t.toggled.connect(func(on): Settings.set_value(key, on))
			_plate.place(t, SPOTS[spot])

	# The painted nav column: only the first group has rows behind it today,
	# so the rest say so when tapped rather than pretending to switch.
	for i in 5:
		var hot := PlateControls.hotspot()
		var index := i
		hot.pressed.connect(func(): _nav(index))
		_plate.place(hot, SPOTS["nav%d" % i])

	var lang := PlateControls.hotspot("زبان")
	lang.pressed.connect(func(): AudioManager.play_sfx("SFX_UI_TAP"))
	_plate.place(lang, SPOTS["drop"])

	for spot in ["close", "save"]:
		var leave := PlateControls.hotspot()
		leave.pressed.connect(_leave)
		_plate.place(leave, SPOTS[spot])

func _nav(index: int) -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	match index:
		3: Router.go("UI-17")
		4: Router.go("UI-14")
		_: pass

func _leave() -> void:
	# Settings save as they change, so both the tick and the cross simply
	# leave; neither can discard anything.
	AudioManager.play_sfx("SFX_UI_TAP")
	Router.go("UI-04")
