class_name OrnateBox
extends StyleBox
## A StyleBox that draws the gilded frame.
##
## This is the hinge of the whole look. Because it is a StyleBox, the theme can
## hand it to Button, PanelContainer, LineEdit and ProgressBar — so every
## screen is framed in gold without a single screen knowing about it.

enum Kind {
	PANEL,     ## a framed surface with corner studs
	WELL,      ## an inset surface: list rows, scroll backgrounds
	PLAQUE,    ## a title plate: framed, no studs
	BUTTON,    ## a raised face with a tight frame
	PARCHMENT, ## a reading surface, gold-edged
	BARE,      ## fill and nothing else
}

@export var kind: Kind = Kind.PANEL
@export var top: Color = Palette.PANEL_LIGHT
@export var bottom: Color = Palette.PANEL_DEEP
@export var radius: float = Palette.R_LG
@export var frame_width: float = Palette.FRAME_W
## Drawn over the fill before the frame, for the focus ring and pressed states.
@export var tint: Color = Color(0, 0, 0, 0)

static func make(kind_: Kind, top_: Color, bottom_: Color, radius_: float = Palette.R_LG,
		frame_: float = Palette.FRAME_W) -> OrnateBox:
	var b := OrnateBox.new()
	b.kind = kind_
	b.top = top_
	b.bottom = bottom_
	b.radius = radius_
	b.frame_width = frame_
	return b

func with_margins(h: int, v: int) -> OrnateBox:
	content_margin_left = h
	content_margin_right = h
	content_margin_top = v
	content_margin_bottom = v
	return self

func _draw(ci: RID, rect: Rect2) -> void:
	if rect.size.x <= 2.0 or rect.size.y <= 2.0:
		return
	match kind:
		Kind.BARE:
			Ornate.draw_panel_fill(ci, rect, radius, top, bottom)
		Kind.WELL:
			Ornate.draw_panel_fill(ci, rect, radius, top, bottom)
			Ornate.draw_frame(ci, rect.grow(-1.0), radius, 2.0, false)
		Kind.PLAQUE:
			Ornate.draw_title_banner(ci, rect)
		Kind.BUTTON:
			Ornate.draw_panel_fill(ci, rect, radius, top, bottom)
			if tint.a > 0.0:
				Ornate.draw_panel_fill(ci, rect, radius, tint, tint)
			Ornate.draw_frame(ci, rect.grow(-1.5), radius, frame_width, false)
		Kind.PARCHMENT:
			Ornate.draw_panel_fill(ci, rect, radius, top, bottom)
			Ornate.draw_frame(ci, rect.grow(-2.0), radius, frame_width, false)
		_:
			Ornate.draw_panel_fill(ci, rect, radius, top, bottom)
			Ornate.draw_frame(ci, rect.grow(-2.0), radius, frame_width, true)
