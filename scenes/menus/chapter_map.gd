extends RazinoScreen
## UI-10 — نقشهٔ فصل‌ها.
##
## GDD §5 screen 4 is explicit that locking must be honest: a locked chapter
## says plainly that it is locked and why, and never dangles a promise to push
## a child towards buying.

func _ready() -> void:
	configure("فصل‌ها", "UI-04", "worldmap", true)
	super._ready()

func build_content() -> void:
	var list := make_scroll()
	for entry in ContentManager.catalog:
		list.add_child(_chapter_card(entry))

func _chapter_card(entry: Dictionary) -> Control:
	var cid := String(entry.get("chapter_id", ""))
	var unlocked := GameState.is_chapter_unlocked(cid)
	var installed := ContentManager.is_installed(cid)
	var complete := GameState.is_chapter_complete(cid)
	var free := String(entry.get("access_type", "paid")) == "free"

	var card := Style.make_night_card()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	card.add_child(row)

	row.add_child(Style.make_art_frame(cid, "book", Vector2(150, 100), unlocked))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(Style.make_title(String(entry.get("title", cid)), Palette.FS_HEADING))
	col.add_child(Style.make_body(String(entry.get("synopsis", "")).left(130) + "…",
		Palette.FS_CAPTION, Palette.SNOW_SOFT))

	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", Palette.PAD_MD)
	col.add_child(facts)
	facts.add_child(_chip("%s صحنه" % Fa.num(int(entry.get("scene_count", 0))), Palette.PANEL_LIGHT))
	facts.add_child(_chip("%s قسمت" % Fa.num(int(entry.get("episode_count", 0))), Palette.PANEL_LIGHT))
	facts.add_child(_chip("رایگان" if free else "خریدنی", Palette.TEAL if free else Palette.GOLD))
	if complete:
		facts.add_child(_chip("تمام شد", Palette.EMERALD))

	var action := VBoxContainer.new()
	action.custom_minimum_size.x = 220
	row.add_child(action)

	if not unlocked:
		action.add_child(Style.make_body("هنوز باز نشده", Palette.FS_CAPTION, Palette.SNOW_SOFT))
		var why := Style.make_body(
			"با تمام‌کردن فصل قبلی باز می‌شود." if free else "این فصل جداگانه عرضه می‌شود.",
			Palette.FS_CAPTION, Palette.LOCKED)
		action.add_child(why)
		if not free:
			var store := Style.make_button("دیدن در فروشگاه", "quiet")
			store.pressed.connect(func(): Router.go("UI-11"))
			action.add_child(store)
	elif not installed:
		action.add_child(Style.make_body("روی دستگاه نیست", Palette.FS_CAPTION, Palette.SNOW_SOFT))
		var get_btn := Style.make_button("دریافت", "secondary")
		get_btn.pressed.connect(func(): Router.go("UI-15", {"chapter_id": cid}))
		action.add_child(get_btn)
	else:
		var play := Style.make_button("ادامه" if GameState.current_chapter == cid else "بازی")
		play.pressed.connect(func(): Router.go("UI-06", {"chapter_id": cid, "resume": GameState.current_chapter == cid}))
		action.add_child(play)

	return card

func _chip(text: String, colour: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", OrnateBox.make(
		OrnateBox.Kind.BUTTON, colour.lightened(0.14), colour.darkened(0.22),
		Palette.R_SM, 2.0).with_margins(Palette.PAD_SM, 4))
	p.add_child(Style.make_body(text, Palette.FS_CAPTION, Palette.SNOW, false))
	return p
