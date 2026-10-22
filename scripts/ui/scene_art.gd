class_name SceneArt
extends RefCounted
## Finds and loads a painted background by its id.
##
## A background can arrive two ways, and they are not interchangeable.
## Chapter one ships inside the APK, so its files go through Godot's import
## pipeline and exist at runtime only as `.ctex` — they must be read with
## ResourceLoader. Chapters two to ten are downloaded into user:// as the
## original WebP, never imported, and must be decoded by hand. This is the
## same split AudioManager already lives with, so the shape here mirrors it.

## Where a shared, non-chapter painting lives (menus, regions, thumbnails).
const SHARED_DIRS := [
	"res://assets/art/backgrounds/",
	"res://assets/art/menu/",
	"res://assets/art/regions/",
	"res://assets/art/thumbnails/",
]

static var _cache: Dictionary = {}

## The texture for an art id, or null when nothing is painted for it yet.
##
## Callers fall back to PlaceholderArt on null. That matters: 45 backgrounds
## are referenced and they arrive a few per day, so a half-painted game is
## the normal state for the whole life of this pipeline, not an error.
static func load_texture(art_id: String, chapter_id: String = "") -> Texture2D:
	if art_id.is_empty():
		return null
	var key := "%s|%s" % [chapter_id, art_id]
	if _cache.has(key):
		return _cache[key]
	var tex := _find(art_id, chapter_id)
	_cache[key] = tex
	return tex

static func _find(art_id: String, chapter_id: String) -> Texture2D:
	# Bundled chapter art, imported into the project.
	if not chapter_id.is_empty():
		for ext in ["webp", "png"]:
			var bundled := "res://content/%s/backgrounds/%s.%s" % [chapter_id, art_id, ext]
			if ResourceLoader.exists(bundled):
				return ResourceLoader.load(bundled) as Texture2D
	for dir in SHARED_DIRS:
		for ext in ["webp", "png"]:
			var shared := "%s%s.%s" % [dir, art_id, ext]
			if ResourceLoader.exists(shared):
				return ResourceLoader.load(shared) as Texture2D
	# Downloaded chapter art, sitting in user:// as the file the package
	# carried. ResourceLoader cannot see it, so it is decoded here.
	var external := _external_path(art_id, chapter_id)
	if not external.is_empty():
		return _load_from_disk(external)
	return null

static func _external_path(art_id: String, chapter_id: String) -> String:
	if chapter_id.is_empty():
		return ContentManager.resolve_external_background(art_id)
	var root := ContentManager.chapter_root(chapter_id)
	if root.is_empty() or root.begins_with("res://"):
		return ""
	for ext in ["webp", "png"]:
		var candidate := "%s/backgrounds/%s.%s" % [root, art_id, ext]
		if FileAccess.file_exists(candidate):
			return candidate
	return ""

static func _load_from_disk(path: String) -> Texture2D:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		Log.warn("SceneArt", "could not read %s" % path)
		return null
	var image := Image.new()
	var err := OK
	match path.get_extension().to_lower():
		"webp": err = image.load_webp_from_buffer(bytes)
		"png": err = image.load_png_from_buffer(bytes)
		_: err = ERR_FILE_UNRECOGNIZED
	if err != OK:
		Log.warn("SceneArt", "could not decode %s (error %d)" % [path, err])
		return null
	return ImageTexture.create_from_image(image)

## Dropped when a chapter is installed or removed, so a freshly downloaded
## painting is not hidden behind a cached null from before the download.
static func forget() -> void:
	_cache.clear()
