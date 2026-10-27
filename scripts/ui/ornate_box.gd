class_name OrnateBox
extends StyleBox
## The old box vocabulary, now drawn to docs/DESIGN.md.
##
## Four visual systems came before this one — an ornate gold frame, a carved
## metal one, a flat outlined one and claymorphism — and all four are gone.
## This file is what is left of the first: its enum and its call shape,
## nothing else. Twenty-two screens ask for their panels through `OrnateBox.make`,
## and keeping that signature is what let the whole game change style in one
## commit instead of twenty-two.
##
## New code should say UiBox. This stays until the last caller is moved,
## and should go when it is — a shim that outlives its migration becomes a
## second way of saying the same thing.

enum Kind {
	PANEL,
	WELL,
	PLAQUE,
	BUTTON,
	PARCHMENT,
	BARE,
}

## Which surface each old kind becomes.
##
## PARCHMENT is the only one that still means what it says: the sheets keep
## cream parchment for dialogue and nothing else, so everything that used to
## be "a card the player reads closely" is a dark panel now.
const UI_KIND := {
	Kind.PANEL: UiBox.Kind.PANEL,
	Kind.WELL: UiBox.Kind.SLOT,
	Kind.PLAQUE: UiBox.Kind.PANEL_PLAIN,
	Kind.BUTTON: UiBox.Kind.BUTTON,
	Kind.PARCHMENT: UiBox.Kind.PARCHMENT,
	Kind.BARE: UiBox.Kind.PANEL_PLAIN,
}

static func make(kind_: Kind, _top_: Color, _bottom_: Color,
		radius_: float = RazinoUI.RADIUS, _frame_: float = 0.0) -> UiBox:
	# The colour pair is dropped. In this design a surface's colour comes
	# from its role, not from its caller — that is what stopped the game
	# having eleven different navies on one screen.
	var radius := RazinoUI.RADIUS
	match kind_:
		Kind.WELL: radius = RazinoUI.RADIUS_SLOT
		Kind.BUTTON: radius = RazinoUI.RADIUS_BUTTON
		Kind.PLAQUE: radius = RazinoUI.RADIUS_BUTTON
	if radius_ >= Palette.R_PILL:
		radius = 999.0
	return UiBox.make(UI_KIND.get(kind_, UiBox.Kind.PANEL)).with_radius(radius)
