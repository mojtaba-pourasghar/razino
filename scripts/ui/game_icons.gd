class_name GameIcons
extends RefCounted
## The icon set, drawn in code.
##
## Sixteen screens need coins, gems, keys, locks and lamps at a dozen sizes.
## Drawing them from primitives keeps them crisp on any phone, keeps the APK
## small, and — unlike generated art — guarantees the coin on the shop screen
## is the same coin as the one on the reward popup.
##
## Every icon fits a unit circle of `radius` around `centre`, so callers can
## place them without knowing which icon they asked for.

static func draw(ci: RID, name: String, centre: Vector2, radius: float,
		colour: Color = Palette.GOLD_BRIGHT) -> void:
	var r := radius
	match name:
		"coin":      _coin(ci, centre, r)
		"gem":       _gem(ci, centre, r)
		"key":       _key(ci, centre, r, colour)
		"lock":      _lock(ci, centre, r, colour)
		"lamp":      _lamp(ci, centre, r, colour)
		"star":      _star(ci, centre, r, colour, 5)
		"heart":     _heart(ci, centre, r, colour)
		"book":      _book(ci, centre, r, colour)
		"map":       _map(ci, centre, r, colour)
		"play":      _play(ci, centre, r, colour)
		"clock":     _clock(ci, centre, r, colour)
		"home":      _home(ci, centre, r, colour)
		"gear":      _gear(ci, centre, r, colour)
		"magnifier": _magnifier(ci, centre, r, colour)
		"chat":      _chat(ci, centre, r, colour)
		"friend":    _friend(ci, centre, r, colour)
		"box":       _box(ci, centre, r, colour)
		"check":     _check(ci, centre, r, colour)
		"download":  _download(ci, centre, r, colour)
		"shield":    _shield(ci, centre, r, colour)
		_:           _star(ci, centre, r, colour, 4)

# — currency ——————————————————————————————————————————————

static func _coin(ci: RID, p: Vector2, r: float) -> void:
	CI.circle(ci, p, r, Palette.GOLD_DEEP)
	CI.circle(ci, p, r * 0.88, Palette.GOLD)
	CI.circle(ci, p - Vector2(r * 0.18, r * 0.2), r * 0.52, Palette.GOLD_BRIGHT)
	CI.circle(ci, p, r * 0.46, Palette.GOLD)
	# The engraved star is what stops it reading as a plain disc.
	_star(ci, p, r * 0.42, Palette.GOLD_DEEP, 5)

static func _gem(ci: RID, p: Vector2, r: float) -> void:
	var top := r * 0.42
	var pts := PackedVector2Array([
		p + Vector2(0, r), p + Vector2(r * 0.82, -top * 0.3),
		p + Vector2(r * 0.46, -r * 0.82), p + Vector2(-r * 0.46, -r * 0.82),
		p + Vector2(-r * 0.82, -top * 0.3),
	])
	CI.poly(ci, pts, Palette.TEAL_LIGHT)
	# Two facets, lit from the upper right, give it volume.
	CI.poly(ci, PackedVector2Array([
		p + Vector2(0, r), p + Vector2(r * 0.82, -top * 0.3), p + Vector2(0, -top * 0.3),
	]), Palette.TEAL_DEEP)
	CI.poly(ci, PackedVector2Array([
		p + Vector2(-r * 0.46, -r * 0.82), p + Vector2(r * 0.46, -r * 0.82),
		p + Vector2(0, -top * 0.3),
	]), Color("8FE4EE"))
	var outline := pts
	outline.append(pts[0])
	CI.polyline(ci, outline, Palette.SNOW, maxf(r * 0.08, 1.0))

# — objects ———————————————————————————————————————————————

static func _key(ci: RID, p: Vector2, r: float, col: Color) -> void:
	var w := maxf(r * 0.22, 2.0)
	CI.arc(ci, p + Vector2(0, -r * 0.45), r * 0.42, 0, TAU, col, w, 20)
	CI.line(ci, p + Vector2(0, -r * 0.05), p + Vector2(0, r), col, w)
	CI.line(ci, p + Vector2(0, r * 0.45), p + Vector2(r * 0.45, r * 0.45), col, w)
	CI.line(ci, p + Vector2(0, r * 0.8), p + Vector2(r * 0.32, r * 0.8), col, w)

static func _lock(ci: RID, p: Vector2, r: float, col: Color) -> void:
	var w := maxf(r * 0.2, 2.0)
	CI.arc(ci, p + Vector2(0, -r * 0.3), r * 0.5, PI, TAU, col, w, 16)
	var body := Rect2(p + Vector2(-r * 0.72, -r * 0.3), Vector2(r * 1.44, r * 1.2))
	CI.rect(ci, body, col)
	CI.circle(ci, p + Vector2(0, r * 0.3), r * 0.18, Palette.PANEL_DEEP)

static func _lamp(ci: RID, p: Vector2, r: float, col: Color) -> void:
	# A hanging lantern: cap, glass, flame.
	CI.line(ci, p + Vector2(0, -r), p + Vector2(0, -r * 0.72), col, maxf(r * 0.12, 1.0))
	CI.rect(ci, Rect2(p + Vector2(-r * 0.42, -r * 0.78), Vector2(r * 0.84, r * 0.22)), col)
	var glass := PackedVector2Array([
		p + Vector2(-r * 0.56, -r * 0.5), p + Vector2(r * 0.56, -r * 0.5),
		p + Vector2(r * 0.36, r * 0.78), p + Vector2(-r * 0.36, r * 0.78),
	])
	CI.poly(ci, glass, Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.55))
	var outline := glass
	outline.append(glass[0])
	CI.polyline(ci, outline, col, maxf(r * 0.12, 1.0))
	CI.circle(ci, p + Vector2(0, r * 0.1), r * 0.22, Palette.SNOW)

static func _star(ci: RID, p: Vector2, r: float, col: Color, points: int) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var a := -PI * 0.5 + PI * float(i) / float(points)
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(p + Vector2(cos(a), sin(a)) * rad)
	CI.poly(ci, pts, col)

static func _heart(ci: RID, p: Vector2, r: float, col: Color) -> void:
	CI.circle(ci, p + Vector2(-r * 0.4, -r * 0.3), r * 0.46, col)
	CI.circle(ci, p + Vector2(r * 0.4, -r * 0.3), r * 0.46, col)
	CI.poly(ci, PackedVector2Array([
		p + Vector2(-r * 0.84, -r * 0.18), p + Vector2(r * 0.84, -r * 0.18), p + Vector2(0, r),
	]), col)

static func _book(ci: RID, p: Vector2, r: float, col: Color) -> void:
	CI.rect(ci, Rect2(p + Vector2(-r * 0.8, -r * 0.7), Vector2(r * 1.6, r * 1.4)), col)
	CI.rect(ci, Rect2(p + Vector2(-r * 0.62, -r * 0.52), Vector2(r * 0.56, r * 1.04)), Palette.PANEL_DEEP)
	CI.rect(ci, Rect2(p + Vector2(r * 0.06, -r * 0.52), Vector2(r * 0.56, r * 1.04)), Palette.PANEL_DEEP)
	CI.line(ci, p + Vector2(0, -r * 0.7), p + Vector2(0, r * 0.7), col, maxf(r * 0.12, 1.0))

static func _map(ci: RID, p: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		p + Vector2(-r, -r * 0.6), p + Vector2(-r * 0.33, -r * 0.82),
		p + Vector2(r * 0.33, -r * 0.5), p + Vector2(r, -r * 0.78),
		p + Vector2(r, r * 0.62), p + Vector2(r * 0.33, r * 0.84),
		p + Vector2(-r * 0.33, r * 0.5), p + Vector2(-r, r * 0.8),
	])
	CI.poly(ci, pts, col)
	CI.circle(ci, p + Vector2(r * 0.1, 0), r * 0.2, Palette.RUBY)

static func _play(ci: RID, p: Vector2, r: float, col: Color) -> void:
	# RTL: play points left, the direction Persian reading moves.
	CI.poly(ci, PackedVector2Array([
		p + Vector2(-r * 0.85, 0), p + Vector2(r * 0.6, -r * 0.8), p + Vector2(r * 0.6, r * 0.8),
	]), col)

static func _clock(ci: RID, p: Vector2, r: float, col: Color) -> void:
	var w := maxf(r * 0.14, 1.5)
	CI.arc(ci, p, r * 0.9, 0, TAU, col, w, 28)
	CI.line(ci, p, p + Vector2(0, -r * 0.6), col, w)
	CI.line(ci, p, p + Vector2(r * 0.45, r * 0.1), col, w)

static func _home(ci: RID, p: Vector2, r: float, col: Color) -> void:
	CI.poly(ci, PackedVector2Array([
		p + Vector2(0, -r), p + Vector2(r, -r * 0.05), p + Vector2(-r, -r * 0.05),
	]), col)
	CI.rect(ci, Rect2(p + Vector2(-r * 0.68, -r * 0.05), Vector2(r * 1.36, r * 0.95)), col)
	CI.rect(ci, Rect2(p + Vector2(-r * 0.2, r * 0.2), Vector2(r * 0.4, r * 0.7)), Palette.PANEL_DEEP)

static func _gear(ci: RID, p: Vector2, r: float, col: Color) -> void:
	var teeth := 8
	for i in teeth:
		var a := TAU * float(i) / float(teeth)
		var dir := Vector2(cos(a), sin(a))
		CI.line(ci, p + dir * r * 0.55, p + dir * r, col, maxf(r * 0.3, 2.0))
	CI.circle(ci, p, r * 0.62, col)
	CI.circle(ci, p, r * 0.26, Palette.PANEL_DEEP)

static func _magnifier(ci: RID, p: Vector2, r: float, col: Color) -> void:
	var w := maxf(r * 0.16, 1.5)
	var lens := p + Vector2(r * 0.15, -r * 0.15)
	CI.arc(ci, lens, r * 0.6, 0, TAU, col, w, 24)
	CI.line(ci, lens + Vector2(-r * 0.42, r * 0.42), p + Vector2(-r * 0.8, r * 0.8), col, w * 1.6)

static func _chat(ci: RID, p: Vector2, r: float, col: Color) -> void:
	CI.rect(ci, Rect2(p + Vector2(-r * 0.9, -r * 0.8), Vector2(r * 1.8, r * 1.3)), col)
	CI.poly(ci, PackedVector2Array([
		p + Vector2(r * 0.2, r * 0.5), p + Vector2(r * 0.6, r * 0.5), p + Vector2(r * 0.2, r),
	]), col)

static func _friend(ci: RID, p: Vector2, r: float, col: Color) -> void:
	for dx in [-r * 0.38, r * 0.38]:
		CI.circle(ci, p + Vector2(dx, -r * 0.38), r * 0.34, col)
		CI.poly(ci, PackedVector2Array([
			p + Vector2(dx - r * 0.5, r * 0.85), p + Vector2(dx - r * 0.42, r * 0.05),
			p + Vector2(dx + r * 0.42, r * 0.05), p + Vector2(dx + r * 0.5, r * 0.85),
		]), col)

static func _box(ci: RID, p: Vector2, r: float, col: Color) -> void:
	CI.rect(ci, Rect2(p + Vector2(-r * 0.9, -r * 0.25), Vector2(r * 1.8, r * 1.1)), col)
	CI.rect(ci, Rect2(p + Vector2(-r, -r * 0.62), Vector2(r * 2.0, r * 0.4)), Palette.GOLD_DEEP)
	CI.rect(ci, Rect2(p + Vector2(-r * 0.16, -r * 0.62), Vector2(r * 0.32, r * 1.47)), Palette.RUBY)

static func _check(ci: RID, p: Vector2, r: float, col: Color) -> void:
	var w := maxf(r * 0.3, 2.0)
	CI.polyline(ci, PackedVector2Array([
		p + Vector2(-r * 0.75, 0), p + Vector2(-r * 0.2, r * 0.6), p + Vector2(r * 0.8, -r * 0.65),
	]), col, w)

static func _download(ci: RID, p: Vector2, r: float, col: Color) -> void:
	var w := maxf(r * 0.2, 2.0)
	CI.line(ci, p + Vector2(0, -r * 0.9), p + Vector2(0, r * 0.25), col, w)
	CI.poly(ci, PackedVector2Array([
		p + Vector2(-r * 0.45, r * 0.1), p + Vector2(r * 0.45, r * 0.1), p + Vector2(0, r * 0.7),
	]), col)
	CI.line(ci, p + Vector2(-r * 0.8, r * 0.85), p + Vector2(r * 0.8, r * 0.85), col, w)

static func _shield(ci: RID, p: Vector2, r: float, col: Color) -> void:
	CI.poly(ci, PackedVector2Array([
		p + Vector2(-r * 0.8, -r * 0.8), p + Vector2(r * 0.8, -r * 0.8),
		p + Vector2(r * 0.65, r * 0.3), p + Vector2(0, r), p + Vector2(-r * 0.65, r * 0.3),
	]), col)
