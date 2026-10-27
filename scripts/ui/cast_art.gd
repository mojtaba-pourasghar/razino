class_name CastArt
extends RefCounted
## The painted cast, loaded on demand.
##
## Each character has a reference sheet and, as they are painted, one image
## per mood. A mood that has not been painted yet falls back to the sheet
## rather than to nothing, so a character never disappears mid-conversation
## because the art is only half delivered — which it will be for a while.
##
## Mirrors UiArt: one cache, cleared when a chapter changes so the textures
## of a chapter nobody is playing stop holding memory on a phone.

const DIR := "res://assets/art/cast/"

static var _cache: Dictionary = {}

## The painting for a character in a mood, or null when none is painted yet.
static func figure(character_id: String, mood: String = "neutral") -> Texture2D:
	var tex := _load("%s_%s" % [character_id, mood])
	if tex != null:
		return tex
	return _load("%s_sheet" % character_id)

static func _load(file: String) -> Texture2D:
	if _cache.has(file):
		return _cache[file]
	var tex: Texture2D = null
	for ext in ["png", "webp"]:
		var path := "%s%s.%s" % [DIR, file, ext]
		if ResourceLoader.exists(path):
			tex = ResourceLoader.load(path) as Texture2D
			break
	_cache[file] = tex
	return tex

static func forget() -> void:
	_cache.clear()
