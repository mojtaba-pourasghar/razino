class_name OrnateBox
extends StyleBox
## The old box vocabulary, now drawn in clay.
##
## Three visual systems came before claymorphism — an ornate gold frame, a
## carved metal one and a flat outlined one — and all three are deleted. This
## file is what is left of the first: its enum and its call shape, nothing
## else. Twenty-two screens ask for their panels through `OrnateBox.make`,
## and keeping that signature is what let the whole game change style in one
## commit instead of twenty-two.
##
## New code should say ClayBox. This stays until the last caller is moved,
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

## Which clay surface each old kind becomes. PARCHMENT no longer means a
## cream sheet with ornamental corners; it means a light surface, because
## clay's light comes from its own two shadows and an ornamented corner has
## nowhere to live on it.
const CLAY_KIND := {
	Kind.PANEL: ClayBox.Kind.SURFACE,
	Kind.WELL: ClayBox.Kind.WELL,
	Kind.PLAQUE: ClayBox.Kind.PLAQUE,
	Kind.BUTTON: ClayBox.Kind.BUTTON,
	Kind.PARCHMENT: ClayBox.Kind.SURFACE,
	Kind.BARE: ClayBox.Kind.SURFACE,
}

static func make(kind_: Kind, top_: Color, _bottom_: Color,
		radius_: float = Clay.RADIUS, _frame_: float = Clay.BORDER) -> ClayBox:
	# The second colour is dropped on purpose. A clay surface is one colour
	# lit by its own inner shadows, so a gradient pair has nothing to do.
	var radius := Clay.RADIUS_PILL if radius_ >= Palette.R_PILL else Clay.RADIUS
	match kind_:
		Kind.WELL: radius = Clay.RADIUS_SM
		Kind.PLAQUE: radius = Clay.RADIUS_PILL
	return ClayBox.make(CLAY_KIND.get(kind_, ClayBox.Kind.SURFACE), top_, radius)
