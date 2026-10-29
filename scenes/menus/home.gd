extends Control
## UI-04 — خانه, the hub a player returns to between chapters.
##
## This screen used to be a second copy of the start screen: the same
## painting, the same title, the same «شروع بازی» button. A player pressed
## start on the splash, watched the intro, built a character, and landed on
## something that looked exactly like where they began — so the only way to
## reach the game was to press start a second time, on a screen that gave no
## sign it was a different screen. That is what made the game feel like it
## had no way in.
##
## It is built to docs/UI_SPEC.md §۲ instead, which never described a menu:
## the player's own capsule, their purse, four ways into the game down one
## side, and at the foot the chapter they are in with the one button that
## carries on playing it. Nothing here repeats the splash.

## Where each piece sits as a fraction of the window, so the composition
## holds from a 19:9 phone to a 4:3 tablet.
##
## These read left to right as the eye sees them, and _place() puts each
## piece in a holder that is laid out left to right so they land where they
## read. Placing the pieces directly does not work: the screen is right to
## left for Persian and Godot mirrors anchors under that, but a piece that
## sets its own direction — the player capsule does, so its avatar stays
## ahead of its name — is not mirrored, so it alone flew to the far side.
const SPOT := {
	"player": Rect2(0.022, 0.030, 0.270, 0.105),
	"purse": Rect2(0.690, 0.030, 0.288, 0.075),
	"rail": Rect2(0.030, 0.200, 0.092, 0.620),
	"arch": Rect2(0.300, 0.110, 0.400, 0.640),
	"chapter": Rect2(0.330, 0.775, 0.340, 0.095),
	"resume": Rect2(0.370, 0.880, 0.260, 0.090),
}

## The four ways into the game, in the order docs/UI_SPEC.md §۲ lists them.
## «خروج» is deliberately absent: quitting belongs on the start screen, and
## having it here was half of why this screen read as a second main menu.
const MENU := [
	{"label": "نقشهٔ جهان", "icon": "map", "ui": "UI-05"},
	{"label": "مأموریت‌ها", "icon": "star", "ui": "UI-20"},
	{"label": "سرنخ‌ها", "icon": "book", "ui": "UI-08"},
	{"label": "فروشگاه", "icon": "gem", "ui": "UI-11"},
]

var _placed: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	Style.attach(self)
	_build()
	resized.connect(_place_all)
	_place_all()

func _build() -> void:
	_paint_backdrop()

	_place(Style.make_player_badge(GameState.player_name, GameState.level,
		GameState.xp, GameState.xp_for_next_level()), "player")

	var purse := HBoxContainer.new()
	purse.alignment = BoxContainer.ALIGNMENT_END
	purse.add_theme_constant_override("separation", Palette.PAD_SM)
	purse.add_child(Style.make_chip("coin", GameState.coins, Palette.GOLD_BRIGHT))
	purse.add_child(Style.make_chip("gem", GameState.gems, Palette.BLUE))
	var gear := Medallion.new("gear", Palette.MEDALLION, false)
	gear.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_go("UI-13"))
	gear.mouse_filter = Control.MOUSE_FILTER_STOP
	purse.add_child(gear)
	_place(purse, "purse")

	# A rail of round medallions rather than a column of worded pills. The
	# direction leans on the silhouette of the round buttons against the
	# dark wall, and a stack of text plates reads as a web page beside it.
	var rail := VBoxContainer.new()
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_theme_constant_override("separation", Palette.PAD_MD)
	for entry: Dictionary in MENU:
		var m := Medallion.new(String(entry["icon"]), 72.0)
		m.icon_colour = Palette.TEAL_LIGHT
		m.tooltip_text = String(entry["label"])
		m.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		m.pressed.connect(_go.bind(String(entry["ui"])))
		rail.add_child(m)
	_place(rail, "rail")

	# The scene, seen through the pointed window the direction is built on.
	var arch := ArchFrame.new()
	for path in ["res://assets/art/backgrounds/ui_town.webp",
			"res://assets/art/backgrounds/ui_splash.webp"]:
		if ResourceLoader.exists(path):
			arch.texture = load(path)
			break
	_place(arch, "arch")

	_place(Style.make_two_line_plaque(_chapter_line(), _chapter_title()), "chapter")

	var resume := Style.make_button(_resume_label(), "primary", "play")
	resume.pressed.connect(_resume)
	_place(resume, "resume")

## The painted town, edge to edge and dimmed to a wall. It is the only thing
## on this screen that is not a control, so it goes down first and never
## takes input.
func _paint_backdrop() -> void:
	var night := ColorRect.new()
	night.color = Palette.NIGHT
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)
	for path in ["res://assets/art/backgrounds/ui_town.webp",
			"res://assets/art/backgrounds/ui_splash.webp"]:
		if not ResourceLoader.exists(path):
			continue
		var art := TextureRect.new()
		art.texture = load(path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Pushed back hard. In the direction this is a wall at the far end
		# of the room, not a picture: it is the same painting that hangs in
		# the window, and if both are lit the same the window disappears.
		art.modulate = Color(0.30, 0.34, 0.46)
		add_child(art)
		break

func _chapter_id() -> String:
	if not GameState.current_chapter.is_empty():
		return GameState.current_chapter
	for entry: Dictionary in ContentManager.catalog:
		var cid := String(entry.get("chapter_id", ""))
		if GameState.is_chapter_unlocked(cid):
			return cid
	return "season_01"

## The catalogue entry for the chapter in play, or an empty one. Its key is
## `chapter_id`; reading `id` is what printed a raw "season_01" on the
## plaque where the chapter's name belongs.
func _chapter_entry() -> Dictionary:
	var cid := _chapter_id()
	for entry: Dictionary in ContentManager.catalog:
		if String(entry.get("chapter_id", "")) == cid:
			return entry
	return {}

func _chapter_title() -> String:
	return String(_chapter_entry().get("title", "فصل تازه"))

func _chapter_line() -> String:
	var sub := String(_chapter_entry().get("subtitle", ""))
	if not sub.is_empty():
		return sub
	var n := _chapter_id().get_slice("_", 1).to_int()
	return "فصل %s" % Fa.num(n if n > 0 else 1)

## Whether there is a scene to drop straight back into, or whether this
## chapter is still waiting to be started.
func _has_position() -> bool:
	return not GameState.current_scene.is_empty()

func _resume_label() -> String:
	return "ادامهٔ بازی" if _has_position() else "شروع فصل"

func _resume() -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	Router.go("UI-20", {"chapter_id": _chapter_id()})

func _go(ui_id: String) -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	var payload := {"chapter_id": _chapter_id()} if ui_id == "UI-20" else {}
	Router.go(ui_id, payload)

# — fraction placement —

func _place(node: Control, spot: String) -> void:
	var holder := Control.new()
	holder.layout_direction = Control.LAYOUT_DIRECTION_LTR
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(holder)
	holder.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_placed.append({"node": holder, "spot": spot})

func _place_all() -> void:
	for item: Dictionary in _placed:
		var node: Control = item["node"]
		var r: Rect2 = SPOT[String(item["spot"])]
		node.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		node.anchor_left = r.position.x
		node.anchor_top = r.position.y
		node.anchor_right = r.position.x + r.size.x
		node.anchor_bottom = r.position.y + r.size.y
		node.offset_left = 0.0
		node.offset_top = 0.0
		node.offset_right = 0.0
		node.offset_bottom = 0.0
