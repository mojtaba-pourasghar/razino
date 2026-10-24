extends RazinoScreen
## UI-22 — کارنامهٔ مرحله.
##
## What a run was worth, broken into the four parts GDD §5.2 weights, so a
## child can see where the score came from and what to do differently. A
## number with no breakdown teaches nothing.
##
## Nothing on this card is a loss. A replay can only raise the record, and the
## card says so plainly — a worse second run is never punished, or a child
## learns not to try again.

var _result: Dictionary = {}
var _stage_id: String = ""
var _chapter_id: String = ""

func _ready() -> void:
	var payload := Router.take_payload()
	_result = payload.get("result", {})
	_stage_id = String(payload.get("stage_id", ""))
	_chapter_id = String(payload.get("chapter_id", GameState.current_chapter))
	configure("کارنامه", "UI-20", "panel", true)
	super._ready()

func build_content() -> void:
	var stage := StageEngine.stage(_stage_id)
	var stars := int(_result.get("stars", 0))

	content.add_child(Style.make_two_line_plaque(
		String(stage.get("title", "مرحله")),
		"%s٪" % Fa.num(int(round(float(_result.get("score", 0.0)) * 100.0)))))

	var star_row := HBoxContainer.new()
	star_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", Palette.PAD_SM)
	for i in StageEngine.STAR_THRESHOLDS.size():
		# Drawn, not painted: the painted star carries its own tile, so three
		# of them side by side read as three identical plaques whatever the
		# score was — which is the one thing this row has to say.
		var star := IconRect.new("star", 64.0,
			Palette.GOLD_BRIGHT if i < stars else Palette.GOLD_DARK)
		star.painted = false
		star_row.add_child(star)
	content.add_child(star_row)

	# The breakdown and the rewards scroll; the two buttons do not, so the way
	# onward is always on screen.
	var scroll := make_scroll()

	var breakdown := Style.make_section("از کجا آمد")
	scroll.add_child(breakdown)
	var col := Style.section_body(breakdown)
	col.add_child(Style.make_stat_row("magnifier", "سرنخ‌ها", "%s از %s" % [
		Fa.num(int(_result.get("clues_found", 0))),
		Fa.num(int(_result.get("clues_total", 0)))]))
	col.add_child(Style.make_stat_row("key", "معماها", "%s از %s" % [
		Fa.num(int(_result.get("puzzles_solved", 0))),
		Fa.num(int(_result.get("puzzles_total", 0)))]))
	col.add_child(Style.make_stat_row("lamp", "راز مرحله",
		"پیدا شد" if bool(_result.get("secret_found", false)) else "پیدا نشد"))
	col.add_child(Style.make_stat_row("clock", "زمان",
		"%s دقیقه" % Fa.num(int(round(float(_result.get("seconds", 0.0)) / 60.0)))))
	if int(_result.get("hints_used", 0)) > 0:
		col.add_child(Style.make_stat_row("shield", "راهنمایی",
			"%s بار" % Fa.num(int(_result.get("hints_used", 0)))))

	var rewards := HBoxContainer.new()
	rewards.layout_direction = Control.LAYOUT_DIRECTION_LTR
	rewards.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards.add_theme_constant_override("separation", Palette.PAD_LG)
	rewards.add_child(Style.make_reward("coin", int(_result.get("coins", 0)), Palette.ORANGE))
	rewards.add_child(Style.make_reward("star", int(_result.get("xp", 0)), Palette.TEAL))
	scroll.add_child(rewards)

	if not bool(_result.get("first_time", true)):
		scroll.add_child(Style.make_quote(
			"این مرحله را قبلاً تمام کرده بودی، پس جایزه کمتر است — "
			+ "ولی رکورد فقط بهتر می‌شود، هیچ‌وقت بدتر."))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", Palette.PAD_MD)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(buttons)

	var again := Style.make_button("دوباره", "quiet")
	again.pressed.connect(func(): Router.go("UI-21", {
		"chapter_id": _chapter_id, "stage_id": _stage_id}))
	buttons.add_child(again)

	var next_id := _next_stage()
	if next_id.is_empty():
		var list := Style.make_button("مرحله‌ها")
		list.pressed.connect(func(): Router.go("UI-20", {"chapter_id": _chapter_id}))
		buttons.add_child(list)
	else:
		var go := Style.make_button("مرحلهٔ بعد")
		go.pressed.connect(func(): Router.go("UI-21", {
			"chapter_id": _chapter_id, "stage_id": next_id}))
		buttons.add_child(go)

## The stage after this one, if it is open now. Empty when this was the last
## one, or when the next is still locked.
func _next_stage() -> String:
	var index := int(StageEngine.stage(_stage_id).get("index", 0))
	for s: Dictionary in StageEngine.stages:
		if int(s.get("index", 0)) != index + 1:
			continue
		var id := String(s.get("stage_id", ""))
		return id if StageEngine.is_open(id) else ""
	return ""
