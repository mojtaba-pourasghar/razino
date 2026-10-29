extends RazinoScreen
## UI-17 — پروفایل, built to docs/UI_SPEC.md §۱۰.
##
## This screen used to be a full-screen painting with live controls pinned
## over the places where the painter had drawn placeholder labels. Three
## things were wrong with that, and only the first was cosmetic: it was
## painted in a green-and-gold with ivy that belongs to no other screen in
## the game; the real numbers sat in little boxes that overflowed the panel
## they were meant to be inside, because nothing was laying them out; and
## the painted Persian in it is misspelled — «ققط» for «فقط» — which no
## image model is ever going to get right and which could not be corrected
## without repainting the screen.
##
## Built from the kit instead, it costs nothing to change a word.

func _ready() -> void:
	configure("پروفایل", "UI-04", "town", true, "friend")
	super._ready()

func build_content() -> void:
	content.add_child(_header())

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", Palette.PAD_SM)
	for b: Button in Style.make_tabs(["آواتار", "آمار", "دستاوردها"], 0):
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	content.add_child(tabs)

	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", Palette.PAD_MD)
	tiles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for tile: Dictionary in _stats():
		var t := Style.make_stat_tile(String(tile["icon"]), String(tile["label"]),
			int(tile["value"]))
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tiles.add_child(t)
	content.add_child(tiles)

	var go := Style.make_button("ادامهٔ بازی", "primary", "play")
	go.custom_minimum_size.x = 280
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void:
		AudioManager.play_sfx("SFX_UI_TAP")
		Router.go("UI-04"))
	content.add_child(go)

## The avatar, the name, the level and how far through it the player is.
func _header() -> Control:
	var card := Style.make_section()
	var body: VBoxContainer = card.get_meta("body")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	body.add_child(row)

	var face := Medallion.new("friend", 96.0, false)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(face)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)

	var shown := GameState.player_name if not GameState.player_name.is_empty() \
		else "بازیکن"
	col.add_child(Style.make_title(shown, Palette.FS_TITLE, Palette.SNOW))
	col.add_child(Style.make_body("سطح %s" % Fa.num(GameState.level),
		Palette.FS_LABEL, Palette.SNOW_SOFT, false))

	var need := GameState.xp_for_next_level()
	col.add_child(Style.make_meter(float(GameState.xp) / maxf(float(need), 1.0), 320.0))
	col.add_child(Style.make_body("%s / %s" % [Fa.num(GameState.xp), Fa.num(need)],
		Palette.FS_CAPTION, Palette.SNOW_SOFT, false))
	return card

## Three counts the player can check against what they have actually done.
## Nothing here is invented: each one is read off GameState.
func _stats() -> Array[Dictionary]:
	var done := 0
	for record: Variant in GameState.stage_records.values():
		if record is Dictionary and bool((record as Dictionary).get("complete", false)):
			done += 1
	return [
		{"icon": "star", "label": "مأموریت‌ها", "value": done},
		{"icon": "book", "label": "سرنخ‌ها", "value": GameState.clues.size()},
		{"icon": "gem", "label": "وسایل", "value": GameState.inventory.size()},
	]
