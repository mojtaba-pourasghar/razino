class_name UiBox
extends StyleBox
## RazinoUI's surfaces as a StyleBox, so every Control wears them.

enum Kind { PANEL, PANEL_PLAIN, BUTTON, PRIMARY, SLOT, PARCHMENT, NONE }

@export var kind: Kind = Kind.PANEL
@export var radius: float = RazinoUI.RADIUS
@export var fill: Color = Palette.PANEL_DEEP
@export var pressed: bool = false
@export var hovered: bool = false

## Which painted piece stands in for each kind, when it has arrived.
const PIECE := {
	Kind.PANEL: "panel",
	Kind.PANEL_PLAIN: "panel",
	Kind.BUTTON: "button_dark",
	Kind.PRIMARY: "button_gold",
	Kind.SLOT: "slot",
}

## A painted piece beats a drawn one wherever it exists. Returns the painted
## StyleBox when the kit has that piece, and null otherwise, so the caller
## falls back to drawing without having to know which pieces have landed.
static func painted(kind_: Kind, h_pad: int, v_pad: int) -> StyleBox:
	if not PIECE.has(kind_):
		return null
	return KitArt.box(String(PIECE[kind_]), h_pad, v_pad)

static func make(kind_: Kind, h_pad: int = 18, v_pad: int = 14) -> UiBox:
	var box := UiBox.new()
	box.kind = kind_
	box.content_margin_left = h_pad
	box.content_margin_right = h_pad
	box.content_margin_top = v_pad
	box.content_margin_bottom = v_pad
	return box

func with_margins(h: int, v: int) -> UiBox:
	content_margin_left = h
	content_margin_right = h
	content_margin_top = v
	content_margin_bottom = v
	return self

func with_fill(colour: Color) -> UiBox:
	fill = colour
	return self

func with_radius(r: float) -> UiBox:
	radius = r
	return self

func state(pressed_: bool, hovered_: bool) -> UiBox:
	var copy := duplicate() as UiBox
	copy.pressed = pressed_
	copy.hovered = hovered_
	return copy

func _draw(ci: RID, rect: Rect2) -> void:
	match kind:
		Kind.PANEL: RazinoUI.panel(ci, rect, radius, fill, true)
		Kind.PANEL_PLAIN: RazinoUI.panel(ci, rect, radius, fill, false)
		Kind.BUTTON: RazinoUI.button(ci, rect, false, pressed, hovered)
		Kind.PRIMARY: RazinoUI.button(ci, rect, true, pressed, hovered)
		Kind.SLOT: RazinoUI.slot(ci, rect, true)
		Kind.PARCHMENT: RazinoUI.parchment(ci, rect, radius)
		Kind.NONE: pass
