class_name ItemArt
extends RefCounted
## The painted objects that go in inventory slots.
##
## This is where the difference between a mockup and the game actually
## lived. The chrome around a panel was never the gap — measured side by
## side, the approved sheet's inventory and this game's were the same dark
## panel with the same hairline. What filled them was not: the sheet holds
## painted potions, a scroll, a coin, a sword, a helmet; the game held flat
## line glyphs. An empty room with good walls still reads as empty.

const DIR := "res://assets/art/items/"

## What each item id in the content is painted as. An id with no painting
## falls back to its drawn glyph, so content can name something before the
## art for it exists.
const FOR_ITEM := {
	"ITEM_MAP_PIECE": "scroll",
	"ITEM_NOTEBOOK": "scroll",
	"ITEM_BRASS_KEY": "key",
	"ITEM_TENTH_KEY": "key",
	"ITEM_GEAR_TEN": "gem",
	"ITEM_TOOLS": "sword",
	"ITEM_LEVER": "sword",
	"ITEM_UNDERMAP": "scroll",
	"ITEM_RECORDER": "gem",
}

## And for the handful of drawn glyph names the screens still ask for.
const FOR_GLYPH := {
	"coin": "coin", "gem": "gem", "key": "key", "book": "scroll",
	"map": "scroll", "box": "armour", "shield": "helmet",
	"magnifier": "potion_blue", "star": "potion_red",
}

static var _cache: Dictionary = {}

static func of_item(item_id: String) -> Texture2D:
	return _load(String(FOR_ITEM.get(item_id, "")))

static func of_glyph(glyph: String) -> Texture2D:
	return _load(String(FOR_GLYPH.get(glyph, "")))

static func by_name(name: String) -> Texture2D:
	return _load(name)

static func _load(name: String) -> Texture2D:
	if name.is_empty():
		return null
	if _cache.has(name):
		return _cache[name]
	var tex: Texture2D = null
	var path := DIR + name + ".png"
	if ResourceLoader.exists(path):
		tex = ResourceLoader.load(path) as Texture2D
	_cache[name] = tex
	return tex

static func forget() -> void:
	_cache.clear()
