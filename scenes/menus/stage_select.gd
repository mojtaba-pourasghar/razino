extends RazinoScreen
## UI-20 — مرحله‌های فصل.
##
## GDD §5.8 makes the stage the thing a player picks, plays and replays, so
## this is the screen between a chapter and the game. It shows every stage in
## order with what the player earned from it: stars, clues found, whether it
## was ever done without a hint.
##
## Locking is the same honesty the chapter list keeps: a locked stage says
## which one opens it, and never offers a way to pay past it — there isn't
## one.

var _chapter_id: String = ""

func _ready() -> void:
	var payload := Router.take_payload()
	_chapter_id = String(payload.get("chapter_id", GameState.current_chapter))
	if _chapter_id.is_empty():
		_chapter_id = "season_01"
	configure("", "UI-05", "worldmap", true)
	super._ready()

func build_content() -> void:
	# The stage list lives in the chapter's own story file, so the chapter has
	# to be loaded before there is anything to show.
	if StageEngine.chapter_id != _chapter_id:
		if not StoryEngine.load_chapter(_chapter_id):
			content.add_child(make_notice("این فصل روی دستگاه خوانده نشد."))
			var back := Style.make_button("بازگشت", "quiet")
			back.pressed.connect(func(): Router.go("UI-05"))
			content.add_child(back)
			return

	header.add_child(Style.make_corner_plaque(String(StoryEngine.story.get("title", "فصل"))))
	# The plaque is added after the header is built, so it lands at the end of
	# the row; moving it to the middle keeps the shell's own arrangement.
	header.move_child(header.get_child(header.get_child_count() - 1), 2)

	content.add_child(_progress_bar())

	var list := make_scroll()
	for stage: Dictionary in StageEngine.stages:
		list.add_child(_stage_card(stage))

## One line that says how far this chapter has come, in stars. It is a line
## rather than a panel because it is a caption on the list below it, and a
## framed panel of its own ate a third of the screen.
func _progress_bar() -> Control:
	var earned := StageEngine.stars_earned()
	var available := StageEngine.stars_available()
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", Palette.PAD_SM)
	var star := IconRect.new("star", 30.0, Palette.GOLD_BRIGHT)
	star.painted = false
	row.add_child(star)
	row.add_child(Style.make_body(
		"%s ستاره از %s" % [Fa.num(earned), Fa.num(available)],
		Palette.FS_LABEL, Palette.SNOW, false))
	var meter := Style.make_meter(
		0.0 if available <= 0 else float(earned) / float(available), 280.0)
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(meter)
	return row

func _stage_card(stage: Dictionary) -> Control:
	var stage_id := String(stage.get("stage_id", ""))
	var record := GameState.stage_record(stage_id)
	var open := StageEngine.is_open(stage_id)
	var done := bool(record.get("completed", false))

	# Parchment, not a framed panel. A painted panel plate draws its corner
	# ornament at source size, so in a row this short it crumples into
	# unreadable scrollwork — the same way the notification list did.
	var card := Style.make_card(Palette.R_MD)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	card.add_child(row)

	# The number, so a child can say "I'm on four" without reading a title.
	var number := Style.make_corner_plaque(
		Fa.num(int(stage.get("index", 0))), Palette.FS_HEADING)
	number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(number)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(Style.make_title(String(stage.get("title", stage_id)),
		Palette.FS_LABEL, Palette.INK))
	# The question is the stage, so it is shown before it is answered and
	# after — a child who replays is chasing the same one.
	var q := Style.make_body(String(stage.get("secret", "")),
		Palette.FS_CAPTION, Palette.INK_SOFT)
	q.autowrap_mode = TextServer.AUTOWRAP_OFF
	q.clip_text = true
	col.add_child(q)

	var facts := HBoxContainer.new()
	facts.layout_direction = Control.LAYOUT_DIRECTION_LTR
	facts.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(facts)
	facts.add_child(_stars(int(record.get("stars", 0))))
	facts.add_child(_fact("magnifier", "%s سرنخ" % Fa.num(
		int(record.get("clues", 0)) if done else int(stage.get("clue_count", 0)))))
	if int(stage.get("puzzle_count", 0)) > 0:
		facts.add_child(_fact("key", "%s معما" % Fa.num(int(stage.get("puzzle_count", 0)))))
	if bool(record.get("no_hint", false)):
		facts.add_child(_fact("shield", "بدون راهنمایی"))

	var action := VBoxContainer.new()
	action.custom_minimum_size.x = 190
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	action.add_theme_constant_override("separation", 2)
	row.add_child(action)

	if not open:
		var lock := IconRect.new("lock", 32.0, Palette.INK_SOFT)
		lock.painted = false
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		action.add_child(lock)
		var why := Style.make_body("با تمام‌کردن مرحلهٔ قبل باز می‌شود",
			Palette.FS_CAPTION, Palette.INK_SOFT)
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		action.add_child(why)
	else:
		var play := Style.make_button("دوباره" if done else "شروع",
			"quiet" if done else "primary")
		play.pressed.connect(func(): Router.go("UI-21", {
			"chapter_id": _chapter_id, "stage_id": stage_id}))
		action.add_child(play)
		if done:
			var best := Style.make_body(
				"بهترین: %s٪" % Fa.num(int(round(float(record.get("score", 0.0)) * 100.0))),
				Palette.FS_CAPTION, Palette.INK_SOFT, false)
			best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			action.add_child(best)

	return card

## One small fact on the parchment: a dark icon and its word, with no chip
## behind it. The gold chips of the dark screens disappear on parchment.
func _fact(icon: String, text: String) -> Control:
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation", 4)
	var mark := IconRect.new(icon, 22.0, Palette.INK_SOFT)
	mark.painted = false
	row.add_child(mark)
	row.add_child(Style.make_body(text, Palette.FS_CAPTION, Palette.INK_SOFT, false))
	return row

## Three stars, the unearned ones left as empty sockets rather than hidden,
## so the player can see what is still on the table.
func _stars(earned: int) -> Control:
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", 2)
	for i in StageEngine.STAR_THRESHOLDS.size():
		var star := IconRect.new("star", 26.0,
			Palette.GOLD_DEEP if i < earned else Palette.PARCHMENT_DIM.darkened(0.25))
		star.painted = false
		row.add_child(star)
	return row
