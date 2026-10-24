class_name PlateControls
extends RefCounted
## The handful of controls that sit on top of a painted screen.
##
## Everything static in a screen — the frame, the panels, the icons, the
## Persian labels — comes from the painting. Only what the player can change
## is drawn, and each of these is drawn to match the painted one it covers,
## sampled from the reference: a gold track with a pale cyan knob, a teal
## pill with a cream knob.

const TRACK_FILLED := Color("E8C06A")
const TRACK_EMPTY := Color("0A2A38")
const TRACK_EDGE := Color("8A6520")
const KNOB := Color("CFF6FF")
const KNOB_EDGE := Color("2E8FA8")
const TOGGLE_ON := Color("179C8C")
const TOGGLE_OFF := Color("27434F")
const TOGGLE_KNOB := Color("FDFBF5")

## A slider that looks like the painted one underneath it.
static func slider(value: float, lo: float = 0.0, hi: float = 1.0) -> HSlider:
	var s := PlateSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = value
	s.focus_mode = Control.FOCUS_ALL
	return s

## A toggle that looks like the painted one underneath it.
static func toggle(on: bool) -> BaseButton:
	var t := PlateToggle.new()
	t.toggle_mode = true
	t.button_pressed = on
	t.focus_mode = Control.FOCUS_ALL
	return t

## An invisible hit area over a painted button, so the painting itself is
## what the player sees pressed.
static func hotspot(tooltip: String = "") -> Button:
	var b := Button.new()
	b.flat = true
	b.tooltip_text = tooltip
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	return b
