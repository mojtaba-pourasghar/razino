class_name ClayWidgets
extends RefCounted
## The few bits of the theme that must be textures rather than drawings.
##
## Godot takes slider grabbers and switch states as icons, not StyleBoxes, so
## they cannot go through ClayBox. They are painted into an Image here —
## still from Palette, still at build time, so they match the drawn clay
## exactly and nothing has to ship as a file.
##
## Clay rules apply the same as everywhere: a thick darker border in the
## shape's own colour, a light band at the top and a shadow at the bottom.

## Anti-aliases by asking how far inside the shape each pixel is.
static func _coverage(d: float) -> float:
	return clampf(0.5 - d, 0.0, 1.0)

## Signed distance to a rounded rectangle, negative inside.
static func _rrect_distance(p: Vector2, half: Vector2, radius: float) -> float:
	var q := p.abs() - half + Vector2(radius, radius)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - radius

## A clay knob: lit at the top, shadowed at the bottom, in a thick border
## of its own darker shade.
static func knob(diameter: int = 34) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(diameter, diameter) * 0.5
	var r := diameter * 0.5 - 1.0
	for y in diameter:
		for x in diameter:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c)
			var inside := _coverage(d - r)
			if inside <= 0.0:
				continue
			var t := clampf((p.y - (c.y - r)) / (r * 2.0), 0.0, 1.0)
			var col := Palette.GOLD_BRIGHT.lightened(0.25).lerp(Palette.GOLD, t)
			# The outer two pixels are the dark seating ring.
			if d > r - Clay.BORDER:
				col = Palette.GOLD_BRIGHT.darkened(0.45)
			col.a = inside
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## The switch used by every CheckButton: a dark well with a gold knob, teal
## when on so "on" reads at a glance without relying on position alone.
static func switch(on: bool, w: int = 72, h: int = 38) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var half := Vector2(w, h) * 0.5 - Vector2(1, 1)
	var radius := h * 0.5 - 1.0
	var track_top := Palette.ACTION.lightened(0.25) if on else Palette.PANEL.lightened(0.10)
	var track_bottom := Palette.ACTION.darkened(0.15) if on else Palette.PANEL.darkened(0.15)
	var knob_centre := Vector2(w - radius - 3.0 if on else radius + 3.0, h * 0.5)
	var knob_r := radius - 4.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5 - w * 0.5, y + 0.5 - h * 0.5)
			var cover := _coverage(_rrect_distance(p, half, radius))
			if cover <= 0.0:
				continue
			var t := float(y) / float(h)
			var col := track_top.lerp(track_bottom, t)
			# A gold rim, then the knob on top of the track.
			if _rrect_distance(p, half, radius) > -2.5:
				col = Palette.GOLD
			var kd := Vector2(x + 0.5, y + 0.5).distance_to(knob_centre)
			if kd < knob_r:
				var kt := clampf((y - (knob_centre.y - knob_r)) / (knob_r * 2.0), 0.0, 1.0)
				col = Palette.GOLD_BRIGHT.lerp(Palette.GOLD_DEEP, kt)
				if kd > knob_r - 2.0:
					col = (Palette.ACTION if on else Palette.PANEL).darkened(0.45)
			col.a = cover
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
