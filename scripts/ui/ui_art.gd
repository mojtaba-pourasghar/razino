class_name UiArt
extends RefCounted
## The painted interface: frames, panels, buttons and icons as art rather
## than geometry.
##
## The screens were drawn in code, and code cannot make painted metal, leaf
## ornament or paper texture — only clean shapes. The approved sheets are
## paintings all the way down, so the chrome is painted too and Godot
## stretches it as a nine-patch.
##
## Every lookup falls back to the drawn version when a piece has not been
## painted yet. That matters: the art arrives a few at a time, so a part-
## painted interface is the normal state, not an error.

const DIR := "res://assets/art/ui/"
const MARGINS := "res://assets/art/ui/nine_patch.json"

static var _plates: Dictionary = {}
static var _icons: Dictionary = {}
static var _margins: Dictionary = {}
static var _margins_loaded: bool = false

## A nine-patch plate — panel, plaque, button, parchment, well.
static func plate(name: String) -> Texture2D:
	return _load(name, _plates)

## A painted icon, looked up by the same name GameIcons draws.
static func icon(name: String) -> Texture2D:
	return _load("icon_%s" % name, _icons)

static func _load(file: String, cache: Dictionary) -> Texture2D:
	if cache.has(file):
		return cache[file]
	var tex: Texture2D = null
	for ext in ["png", "webp"]:
		var path := "%s%s.%s" % [DIR, file, ext]
		if ResourceLoader.exists(path):
			tex = ResourceLoader.load(path) as Texture2D
			break
	cache[file] = tex
	return tex

## How much of a plate is corner ornament, as a fraction of its size. The
## generator records this per plate because the ornament is not the same
## size on a button as on a panel.
static func margin_of(name: String) -> float:
	if not _margins_loaded:
		_margins_loaded = true
		if FileAccess.file_exists(MARGINS):
			var parsed: Variant = JSON.parse_string(
				FileAccess.get_file_as_string(MARGINS))
			if parsed is Dictionary:
				_margins = parsed
	return float(_margins.get(name, 0.3))

## A StyleBox cut from a painted plate, or null when that plate has not been
## painted yet and the caller should draw its own.
##
## `tint` recolours the plate. One painted panel in a neutral teal can serve
## as the raised panel, the inset well and the locked card, which is why the
## generator paints six plates rather than twenty.
static func box(name: String, tint: Color = Color.WHITE,
		h_pad: int = Palette.PAD_MD, v_pad: int = Palette.PAD_SM) -> StyleBoxTexture:
	var tex := plate(name)
	if tex == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	var m := margin_of(name) * float(mini(tex.get_width(), tex.get_height()))
	sb.set_texture_margin_all(m)
	sb.modulate_color = tint
	sb.content_margin_left = h_pad
	sb.content_margin_right = h_pad
	sb.content_margin_top = v_pad
	sb.content_margin_bottom = v_pad
	# The ornament would smear if Godot stretched it; tiling the straight
	# runs keeps the metal's grain the same length everywhere.
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb

## Dropped when new art lands mid-session.
static func forget() -> void:
	_plates.clear()
	_icons.clear()
	_margins.clear()
	_margins_loaded = false
