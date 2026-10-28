class_name UiBox
extends StyleBox
## RazinoUI's surfaces as a StyleBox, so every Control wears them.

enum Kind { PANEL, PANEL_PLAIN, BUTTON, PRIMARY, SLOT, PARCHMENT, NONE, TAB_ON, TAB_OFF }

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
	Kind.PARCHMENT: "parchment",
	Kind.TAB_ON: "tab_active",
	Kind.TAB_OFF: "tab_idle",
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
	if _draw_painted(ci, rect):
		return
	match kind:
		Kind.PANEL: RazinoUI.panel(ci, rect, radius, fill, true)
		Kind.PANEL_PLAIN: RazinoUI.panel(ci, rect, radius, fill, false)
		Kind.BUTTON: RazinoUI.button(ci, rect, false, pressed, hovered)
		Kind.PRIMARY: RazinoUI.button(ci, rect, true, pressed, hovered)
		Kind.SLOT: RazinoUI.slot(ci, rect, true)
		Kind.PARCHMENT: RazinoUI.parchment(ci, rect, radius)
		Kind.TAB_ON: RazinoUI.button(ci, rect, true, pressed, hovered)
		Kind.TAB_OFF: RazinoUI.panel(ci, rect, radius, fill, false)
		Kind.NONE: pass

## Wears the kit piece for this kind when it has been painted, so a screen
## that asks for a drawn panel gets the painted one without knowing.
##
## A nine-patch draws its corners at texture pixels, so a box smaller than
## two corners would fold them over each other. Such a box is drawn at a
## larger size and scaled down instead, which shrinks the corners with it.
func _draw_painted(ci: RID, rect: Rect2) -> bool:
	if not PIECE.has(kind):
		return false
	var name := String(PIECE[kind])
	var tex := KitArt.piece(name)
	var m := float(KitArt.margin(name))
	if tex == null or m <= 0.0 or rect.size.x < 2.0 or rect.size.y < 2.0:
		return false
	var k := minf(1.0, minf(rect.size.x, rect.size.y) / (m * 2.0))
	var tint := KitArt.tint(name)
	if pressed:
		tint *= Color(0.8, 0.78, 0.74)
	elif hovered:
		tint *= Color(1.15, 1.1, 1.02)
	var at := Rect2(rect.position / k, rect.size / k)
	if k < 1.0:
		RenderingServer.canvas_item_add_set_transform(ci,
			Transform2D(0.0, Vector2(k, k), 0.0, Vector2.ZERO))
	RenderingServer.canvas_item_add_nine_patch(ci, at,
		Rect2(Vector2.ZERO, tex.get_size()), tex.get_rid(),
		Vector2(m, m), Vector2(m, m),
		RenderingServer.NINE_PATCH_STRETCH, RenderingServer.NINE_PATCH_STRETCH,
		true, tint)
	if k < 1.0:
		RenderingServer.canvas_item_add_set_transform(ci, Transform2D.IDENTITY)
	return true
