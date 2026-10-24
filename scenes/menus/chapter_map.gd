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

	# Parchment, not a framed panel. A painted panel plate draws its corner
	# ornament at source size, so in a row this short it crumples over the
	# title — the chapter names were unreadable under the scrollwork.
	var card := Style.make_card(Palette.R_MD)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	card.add_child(row)

	row.add_child(Style.make_art_frame(cid, "book", Vector2(150, 100), unlocked))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(Style.make_title(String(entry.get("title", cid)),
		Palette.FS_HEADING, Palette.INK))
	col.add_child(Style.make_body(String(entry.get("synopsis", "")).left(130) + "…",
		Palette.FS_CAPTION, Palette.INK_SOFT))

	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", Palette.PAD_MD)
	col.add_child(facts)
	facts.add_child(_fact("%s صحنه" % Fa.num(int(entry.get("scene_count", 0)))))
	facts.add_child(_fact("%s قسمت" % Fa.num(int(entry.get("episode_count", 0)))))
	facts.add_child(_chip("رایگان" if free else "خریدنی",
		Palette.TEAL if free else Palette.GOLD_DEEP))
	if complete:
		facts.add_child(_chip("تمام شد", Palette.EMERALD))

	var action := VBoxContainer.new()
	action.custom_minimum_size.x = 200
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	action.add_theme_constant_override("separation", 2)
	row.add_child(action)

	if not unlocked:
		action.add_child(_note("هنوز باز نشده"))
		action.add_child(_note("با تمام‌کردن فصل قبلی باز می‌شود."
			if free else "این فصل جداگانه عرضه می‌شود."))
		if not free:
			var store := Style.make_button("دیدن در فروشگاه", "quiet")
			store.pressed.connect(func(): Router.go("UI-11"))
			action.add_child(store)
	elif not installed:
		action.add_child(_note("روی دستگاه نیست"))
		var get_btn := Style.make_button("دریافت", "secondary")
		get_btn.pressed.connect(func(): Router.go("UI-15", {"chapter_id": cid}))
		action.add_child(get_btn)
	else:
		# Into the stage list, not straight into the scene: a chapter is
		# played one stage at a time, and each is packed for before it starts
		# (GDD §5.8). Carrying on from where the player stopped is the home
		# screen's job, which is where a half-finished chapter is picked up.
		var play := Style.make_button("مرحله‌ها")
		play.pressed.connect(func(): Router.go("UI-20", {"chapter_id": cid}))
		action.add_child(play)

	return card

## A plain fact on parchment. The dark chips of the night screens vanish
## against cream, so a counted fact is just ink.
func _fact(text: String) -> Control:
	return Style.make_body(text, Palette.FS_CAPTION, Palette.INK_SOFT, false)

func _note(text: String) -> Label:
	var l := Style.make_body(text, Palette.FS_CAPTION, Palette.INK_SOFT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _chip(text: String, colour: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", OrnateBox.make(
		OrnateBox.Kind.BUTTON, colour.lightened(0.14), colour.darkened(0.22),
		Palette.R_SM, 2.0).with_margins(Palette.PAD_SM, 4))
	p.add_child(Style.make_body(text, Palette.FS_CAPTION, Palette.SNOW, false))
	return p
