extends RazinoScreen
## UI-18 — اعلان‌ها و جوایز.
##
## This was the second of the two screens still built as a full-screen
## painting with invisible buttons laid over it. The rows in that painting
## were fixed: five cards with painted Persian, painted times and painted
## icons that said the same five things forever, whatever the player had
## actually done. Tapping one went somewhere real, so it worked, but it
## could never tell the truth.
##
## Built from the kit, each row is read from the game's own state, and the
## screen says so plainly when there is nothing to report rather than
## showing five invented notices.

func _ready() -> void:
	configure("اعلان‌ها", "UI-04", "town", true, "star")
	super._ready()

func build_content() -> void:
	var notices := _notices()
	if notices.is_empty():
		var empty := Style.make_section()
		var body: VBoxContainer = empty.get_meta("body")
		var line := Style.make_body("هنوز خبری نیست. وقتی چیزی پیدا کنی یا مرحله‌ای را تمام کنی، اینجا می‌آید.",
			Palette.FS_BODY, Palette.SNOW_SOFT)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(line)
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(empty)
	else:
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", Palette.PAD_SM)
		scroll.add_child(list)
		for n: Dictionary in notices:
			list.add_child(_row(n))

	var go := Style.make_button("برگرد به خانه", "primary", "home")
	go.custom_minimum_size.x = 280
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void:
		AudioManager.play_sfx("SFX_UI_TAP")
		Router.go("UI-04"))
	content.add_child(go)

func _row(n: Dictionary) -> Control:
	var card := Style.make_list_card(String(n["icon"]), String(n["title"]),
		String(n["body"]))
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var hit := Button.new()
	hit.flat = true
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var target := String(n["ui"])
	hit.pressed.connect(func() -> void:
		AudioManager.play_sfx("SFX_UI_TAP")
		Router.go(target))
	card.add_child(hit)
	return card

## What the player has actually done, newest first. Each entry is derived,
## never stored, so this screen cannot drift out of step with the save.
func _notices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if GameState.clues.size() > 0:
		out.append({"icon": "book", "ui": "UI-08", "title": "سرنخ تازه",
			"body": "%s سرنخ در دفترچه داری." % Fa.num(GameState.clues.size())})
	if GameState.inventory.size() > 0:
		out.append({"icon": "gem", "ui": "UI-19", "title": "وسیلهٔ تازه",
			"body": "%s چیز در کوله‌بار داری." % Fa.num(GameState.inventory.size())})
	var done := 0
	for record: Variant in GameState.stage_records.values():
		if record is Dictionary and bool((record as Dictionary).get("complete", false)):
			done += 1
	if done > 0:
		out.append({"icon": "star", "ui": "UI-20", "title": "مرحله تمام شد",
			"body": "%s مرحله را تمام کرده‌ای." % Fa.num(done)})
	if GameState.coins > 0 or GameState.gems > 0:
		out.append({"icon": "coin", "ui": "UI-11", "title": "کیف پول",
			"body": "%s سکه و %s الماس داری." % [Fa.num(GameState.coins), Fa.num(GameState.gems)]})
	return out
